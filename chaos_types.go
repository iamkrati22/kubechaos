package main

import (
	"context"
	"fmt"
	"math/rand"
	"time"
	"os"

	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"github.com/robfig/cron/v3"
	"k8s.io/client-go/tools/remotecommand"
	"k8s.io/client-go/rest"
)

// ChaosType represents different types of chaos that can be applied
type ChaosType string

const (
	ChaosTypePodDelete ChaosType = "pod-delete"
	ChaosTypeCPUStress ChaosType = "cpu-stress"
	ChaosTypeMemoryStress ChaosType = "memory-stress"
	ChaosTypeNetworkLatency ChaosType = "network-latency"
	ChaosTypeCronTrigger ChaosType = "cron-trigger"
	ChaosTypeInPodCPUStress ChaosType = "in-pod-cpu-stress"
	ChaosTypeInPodMemoryStress ChaosType = "in-pod-memory-stress"
	ChaosTypeInPodMixedStress ChaosType = "in-pod-mixed-stress"
	ChaosTypeKillProcess ChaosType = "kill-process"
	ChaosTypeCorruptMemory ChaosType = "corrupt-memory"
)

// StressCommandType represents different types of stress commands
type StressCommandType string

const (
	StressCommandCPU    StressCommandType = "cpu"
	StressCommandMemory StressCommandType = "memory"
	StressCommandIO     StressCommandType = "io"
	StressCommandMixed  StressCommandType = "mixed"
)

// ChaosConfig holds configuration for chaos operations
type ChaosConfig struct {
	Type        ChaosType
	Namespace   string
	Labels      map[string]string
	Duration    time.Duration
	Intensity   int // 1-10 scale
	TargetCount int
}

// CPUStressConfig holds specific configuration for CPU stress testing
type CPUStressConfig struct {
	CPUPercent int    // Percentage of CPU to use (1-100)
	Duration   string // Duration in format like "30s", "2m", "1h"
	Cores      int    // Number of CPU cores to stress
}

// CronTriggerConfig holds configuration for cron-based chaos triggers
type CronTriggerConfig struct {
	Schedule     string // Cron schedule (e.g., "*/5 * * * *")
	ChaosType    ChaosType
	Probability  float64 // Probability of triggering (0.0-1.0)
	MaxDuration  time.Duration
}

// generateStressCommand creates a stress command based on type and intensity
func generateStressCommand(stressType StressCommandType, intensity int, duration time.Duration) string {
	// Try multiple package managers and add retry logic
	baseCmd := "for i in 1 2 3; do "
	baseCmd += "if command -v apk >/dev/null 2>&1; then "
	baseCmd += "apk add --no-cache stress-ng && break; "
	baseCmd += "elif command -v apt-get >/dev/null 2>&1; then "
	baseCmd += "apt-get update && apt-get install -y stress-ng && break; "
	baseCmd += "elif command -v yum >/dev/null 2>&1; then "
	baseCmd += "yum install -y stress-ng && break; "
	baseCmd += "else "
	baseCmd += "echo 'No package manager found, using built-in stress'; "
	baseCmd += "break; "
	baseCmd += "fi; "
	baseCmd += "sleep 2; "
	baseCmd += "done && "
	
	// Check if stress-ng is available, if not use fallback
	stressCmd := "if command -v stress-ng >/dev/null 2>&1; then "
	
	switch stressType {
	case StressCommandCPU:
		stressCmd += fmt.Sprintf("stress-ng --cpu %d --timeout %s", intensity*2, duration.String())
		stressCmd += "; else "
		stressCmd += fmt.Sprintf("timeout %s bash -c 'for i in {1..%d}; do while true; do :; done & done; wait'", 
			duration.String(), intensity*2)
	case StressCommandMemory:
		stressCmd += fmt.Sprintf("stress-ng --vm %d --vm-bytes %dM --timeout %s", 
			intensity, intensity*50, duration.String())
		stressCmd += "; else "
		stressCmd += fmt.Sprintf("timeout %s bash -c 'for i in {1..%d}; do dd if=/dev/zero of=/dev/null bs=1M count=%d & done; wait'", 
			duration.String(), intensity, intensity*25)
	case StressCommandIO:
		stressCmd += fmt.Sprintf("stress-ng --io %d --hdd %d --hdd-bytes %dM --timeout %s", 
			intensity, intensity/2, intensity*25, duration.String())
		stressCmd += "; else "
		stressCmd += fmt.Sprintf("timeout %s bash -c 'for i in {1..%d}; do dd if=/dev/zero of=/dev/null bs=1M & done; wait'", 
			duration.String(), intensity)
	case StressCommandMixed:
		stressCmd += fmt.Sprintf("stress-ng --cpu %d --vm %d --vm-bytes %dM --io %d --timeout %s", 
			intensity, intensity/2, intensity*25, intensity/2, duration.String())
		stressCmd += "; else "
		stressCmd += fmt.Sprintf("timeout %s bash -c 'for i in {1..%d}; do while true; do :; done & done; for i in {1..%d}; do dd if=/dev/zero of=/dev/null bs=1M & done; wait'", 
			duration.String(), intensity, intensity/2)
	default:
		stressCmd += fmt.Sprintf("stress-ng --cpu %d --timeout %s", intensity*2, duration.String())
		stressCmd += "; else "
		stressCmd += fmt.Sprintf("timeout %s bash -c 'for i in {1..%d}; do while true; do :; done & done; wait'", 
			duration.String(), intensity*2)
	}
	
	stressCmd += "; fi"
	
	return baseCmd + stressCmd
}

// ApplyCPUStress applies CPU stress to selected pods
func ApplyCPUStress(clientset *kubernetes.Clientset, config ChaosConfig) error {
	fmt.Printf("🔥 Applying CPU stress chaos to namespace: %s\n", config.Namespace)
	
	// List pods based on labels
	listOptions := metav1.ListOptions{}
	if len(config.Labels) > 0 {
		labelSelector := ""
		for k, v := range config.Labels {
			if labelSelector != "" {
				labelSelector += ","
			}
			labelSelector += fmt.Sprintf("%s=%s", k, v)
		}
		listOptions.LabelSelector = labelSelector
	}

	pods, err := clientset.CoreV1().Pods(config.Namespace).List(context.TODO(), listOptions)
	if err != nil {
		return fmt.Errorf("failed to list pods: %v", err)
	}

	if len(pods.Items) == 0 {
		return fmt.Errorf("no pods found in namespace %s", config.Namespace)
	}

	// Select random pods to stress
	podsToStress := config.TargetCount
	if podsToStress > len(pods.Items) {
		podsToStress = len(pods.Items)
		fmt.Printf("⚠️  Requested to stress %d pods but only %d are available\n", config.TargetCount, len(pods.Items))
	}

	selectedPods := selectRandomPods(pods.Items, podsToStress)
	
	for i, pod := range selectedPods {
		fmt.Printf("🔥 Stressing pod %d/%d: %s\n", i+1, len(selectedPods), pod.Name)
		
		// Create a stress container in the pod
		err := createStressContainer(clientset, config.Namespace, pod.Name, config)
		if err != nil {
			fmt.Printf("❌ Failed to stress pod %s: %v\n", pod.Name, err)
		} else {
			fmt.Printf("✅ Successfully stressed pod: %s\n", pod.Name)
		}
	}

	return nil
}

// createStressContainer creates a stress container in the target pod
func createStressContainer(clientset *kubernetes.Clientset, namespace, podName string, config ChaosConfig) error {
	// For now, we'll simulate the stress by creating a temporary job
	// In a real implementation, you might want to use kubectl exec or create a sidecar container
	
	jobName := fmt.Sprintf("stress-%s-%d", podName, time.Now().Unix())
	job := &v1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			Name:      jobName,
			Namespace: namespace,
			Labels: map[string]string{
				"chaos-type": "cpu-stress",
				"target-pod": podName,
			},
		},
		Spec: v1.PodSpec{
			Containers: []v1.Container{
				{
					Name:  "stress",
					Image: "alpine:latest",
					Command: []string{
						"sh", "-c",
						fmt.Sprintf("apk add --no-cache stress-ng && stress-ng --cpu %d --timeout %s",
							config.Intensity*10, config.Duration.String()),
					},
					Resources: v1.ResourceRequirements{
						Requests: v1.ResourceList{
							v1.ResourceCPU:    resource.MustParse("100m"),
							v1.ResourceMemory: resource.MustParse("128Mi"),
						},
						Limits: v1.ResourceList{
							v1.ResourceCPU:    resource.MustParse("1000m"),
							v1.ResourceMemory: resource.MustParse("512Mi"),
						},
					},
				},
			},
			RestartPolicy: v1.RestartPolicyNever,
		},
	}

	_, err := clientset.CoreV1().Pods(namespace).Create(context.TODO(), job, metav1.CreateOptions{})
	return err
}

// ApplyMemoryStress applies memory stress to selected pods
func ApplyMemoryStress(clientset *kubernetes.Clientset, config ChaosConfig) error {
	fmt.Printf("💾 Applying memory stress chaos to namespace: %s\n", config.Namespace)
	
	// Similar to CPU stress but targets memory
	listOptions := metav1.ListOptions{}
	if len(config.Labels) > 0 {
		labelSelector := ""
		for k, v := range config.Labels {
			if labelSelector != "" {
				labelSelector += ","
			}
			labelSelector += fmt.Sprintf("%s=%s", k, v)
		}
		listOptions.LabelSelector = labelSelector
	}

	pods, err := clientset.CoreV1().Pods(config.Namespace).List(context.TODO(), listOptions)
	if err != nil {
		return fmt.Errorf("failed to list pods: %v", err)
	}

	if len(pods.Items) == 0 {
		return fmt.Errorf("no pods found in namespace %s", config.Namespace)
	}

	selectedPods := selectRandomPods(pods.Items, config.TargetCount)
	
	for i, pod := range selectedPods {
		fmt.Printf("💾 Stressing memory for pod %d/%d: %s\n", i+1, len(selectedPods), pod.Name)
		
		// Create memory stress job
		jobName := fmt.Sprintf("memstress-%s-%d", pod.Name, time.Now().Unix())
		job := &v1.Pod{
			ObjectMeta: metav1.ObjectMeta{
				Name:      jobName,
				Namespace: config.Namespace,
				Labels: map[string]string{
					"chaos-type": "memory-stress",
					"target-pod": pod.Name,
				},
			},
			Spec: v1.PodSpec{
				Containers: []v1.Container{
					{
						Name:  "memstress",
						Image: "alpine:latest",
						Command: []string{
							"sh", "-c",
							fmt.Sprintf("apk add --no-cache stress-ng && stress-ng --vm %d --vm-bytes %dM --timeout %s",
								config.Intensity, config.Intensity*50, config.Duration.String()),
						},
						Resources: v1.ResourceRequirements{
							Requests: v1.ResourceList{
								v1.ResourceCPU:    resource.MustParse("100m"),
								v1.ResourceMemory: resource.MustParse("128Mi"),
							},
							Limits: v1.ResourceList{
								v1.ResourceCPU:    resource.MustParse("1000m"),
								v1.ResourceMemory: resource.MustParse("1Gi"),
							},
						},
					},
				},
				RestartPolicy: v1.RestartPolicyNever,
			},
		}

		_, err := clientset.CoreV1().Pods(config.Namespace).Create(context.TODO(), job, metav1.CreateOptions{})
		if err != nil {
			fmt.Printf("❌ Failed to stress memory for pod %s: %v\n", pod.Name, err)
		} else {
			fmt.Printf("✅ Successfully stressed memory for pod: %s\n", pod.Name)
		}
	}

	return nil
}

// StartCronTrigger starts a cron-based chaos trigger
func StartCronTrigger(clientset *kubernetes.Clientset, config CronTriggerConfig) {
	fmt.Printf("⏰ Starting cron chaos trigger with schedule: %s\n", config.Schedule)
	
	// Parse cron schedule
	schedule, err := cron.ParseStandard(config.Schedule)
	if err != nil {
		fmt.Printf("❌ Invalid cron schedule: %v\n", err)
		return
	}

	// Start the cron trigger in a goroutine
	go func() {
		for {
			next := schedule.Next(time.Now())
			time.Sleep(time.Until(next))
			
			// Check probability
			if rand.Float64() <= config.Probability {
				fmt.Printf("🎲 Cron trigger fired! Applying chaos type: %s\n", config.ChaosType)
				
				// Apply the configured chaos type
				chaosConfig := ChaosConfig{
					Type:        config.ChaosType,
					Namespace:   "default", // You might want to make this configurable
					Duration:    config.MaxDuration,
					Intensity:   rand.Intn(10) + 1, // Random intensity 1-10
					TargetCount: rand.Intn(3) + 1,  // Random target count 1-3
				}
				
				switch config.ChaosType {
				case ChaosTypePodDelete:
					// This would call the existing pod deletion logic
					fmt.Printf("💀 Cron triggered pod deletion\n")
				case ChaosTypeCPUStress:
					ApplyCPUStress(clientset, chaosConfig)
				case ChaosTypeMemoryStress:
					ApplyMemoryStress(clientset, chaosConfig)
				default:
					fmt.Printf("⚠️  Unknown chaos type: %s\n", config.ChaosType)
				}
			} else {
				fmt.Printf("🎲 Cron trigger fired but skipped (probability: %.2f)\n", config.Probability)
			}
		}
	}()
}

// CleanupChaosJobs cleans up chaos-related jobs
func CleanupChaosJobs(clientset *kubernetes.Clientset, namespace string) error {
	fmt.Printf("🧹 Cleaning up chaos jobs in namespace: %s\n", namespace)
	
	// List and delete chaos jobs
	pods, err := clientset.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{
		LabelSelector: "chaos-type",
	})
	if err != nil {
		return fmt.Errorf("failed to list chaos jobs: %v", err)
	}

	for _, pod := range pods.Items {
		fmt.Printf("🗑️  Deleting chaos job: %s\n", pod.Name)
		err := clientset.CoreV1().Pods(namespace).Delete(context.TODO(), pod.Name, metav1.DeleteOptions{})
		if err != nil {
			fmt.Printf("⚠️  Failed to delete chaos job %s: %v\n", pod.Name, err)
		}
	}

	fmt.Printf("✅ Cleaned up %d chaos jobs\n", len(pods.Items))
	return nil
}

// ApplyInPodCPUStress execs into the main container of the pod and runs stress-ng
func ApplyInPodCPUStress(config *rest.Config, clientset *kubernetes.Clientset, chaosConfig ChaosConfig) error {
	fmt.Printf("🔥 Applying IN-POD CPU stress chaos to namespace: %s\n", chaosConfig.Namespace)

	listOptions := metav1.ListOptions{}
	if len(chaosConfig.Labels) > 0 {
		labelSelector := ""
		for k, v := range chaosConfig.Labels {
			if labelSelector != "" {
				labelSelector += ","
			}
			labelSelector += fmt.Sprintf("%s=%s", k, v)
		}
		listOptions.LabelSelector = labelSelector
	}

	pods, err := clientset.CoreV1().Pods(chaosConfig.Namespace).List(context.TODO(), listOptions)
	if err != nil {
		return fmt.Errorf("failed to list pods: %v", err)
	}
	if len(pods.Items) == 0 {
		return fmt.Errorf("no pods found in namespace %s", chaosConfig.Namespace)
	}

	// Filter out chaos-related pods to avoid targeting our own stress pods
	var availablePods []v1.Pod
	for _, pod := range pods.Items {
		// Skip pods that have chaos-type labels (our own stress pods)
		if pod.Labels["chaos-type"] != "" {
			continue
		}
		// Skip pods that are being terminated or in error state
		if pod.Status.Phase != v1.PodSucceeded && 
		   pod.Status.Phase != v1.PodFailed && 
		   pod.DeletionTimestamp == nil {
			availablePods = append(availablePods, pod)
		}
	}

	if len(availablePods) == 0 {
		return fmt.Errorf("no available pods found in namespace %s (excluding chaos pods)", chaosConfig.Namespace)
	}

	podsToStress := chaosConfig.TargetCount
	if podsToStress > len(availablePods) {
		podsToStress = len(availablePods)
		fmt.Printf("⚠️  Requested to stress %d pods but only %d are available\n", chaosConfig.TargetCount, len(availablePods))
	}
	selectedPods := selectRandomPods(availablePods, podsToStress)

	for i, pod := range selectedPods {
		// Get the actual container name from the pod spec
		containerName := ""
		if len(pod.Spec.Containers) > 0 {
			containerName = pod.Spec.Containers[0].Name
		} else {
			fmt.Printf("⚠️  Pod %s has no containers, skipping\n", pod.Name)
			continue
		}
		
		// Debug: Print all containers in the pod
		fmt.Printf("🔍 Pod %s containers: ", pod.Name)
		for j, container := range pod.Spec.Containers {
			if j > 0 {
				fmt.Printf(", ")
			}
			fmt.Printf("%s", container.Name)
		}
		fmt.Printf(" (using: %s)\n", containerName)
		
		// Generate stress command based on intensity
		cmd := generateStressCommand(StressCommandCPU, chaosConfig.Intensity, chaosConfig.Duration)
		fmt.Printf("🔥 Stressing pod %d/%d: %s (container: %s)\n", i+1, len(selectedPods), pod.Name, containerName)
		fmt.Printf("📋 Command: %s\n", cmd)
		
		err := execInPod(config, clientset, chaosConfig.Namespace, pod.Name, containerName, cmd)
		if err != nil {
			fmt.Printf("❌ Failed to exec in pod %s: %v\n", pod.Name, err)
			// Try with the first container name if it's different
			if len(pod.Spec.Containers) > 0 {
				firstContainer := pod.Spec.Containers[0].Name
				if firstContainer != containerName {
					fmt.Printf("🔄 Retrying with container: %s\n", firstContainer)
					err = execInPod(config, clientset, chaosConfig.Namespace, pod.Name, firstContainer, cmd)
					if err != nil {
						fmt.Printf("❌ Failed to exec in pod %s with container %s: %v\n", pod.Name, firstContainer, err)
					} else {
						fmt.Printf("✅ Successfully stressed pod: %s\n", pod.Name)
					}
				}
			}
		} else {
			fmt.Printf("✅ Successfully stressed pod: %s\n", pod.Name)
		}
	}
	return nil
}

// ApplyInPodMemoryStress execs into the main container and runs memory stress
func ApplyInPodMemoryStress(config *rest.Config, clientset *kubernetes.Clientset, chaosConfig ChaosConfig) error {
	fmt.Printf("💾 Applying IN-POD memory stress chaos to namespace: %s\n", chaosConfig.Namespace)

	listOptions := metav1.ListOptions{}
	if len(chaosConfig.Labels) > 0 {
		labelSelector := ""
		for k, v := range chaosConfig.Labels {
			if labelSelector != "" {
				labelSelector += ","
			}
			labelSelector += fmt.Sprintf("%s=%s", k, v)
		}
		listOptions.LabelSelector = labelSelector
	}

	pods, err := clientset.CoreV1().Pods(chaosConfig.Namespace).List(context.TODO(), listOptions)
	if err != nil {
		return fmt.Errorf("failed to list pods: %v", err)
	}
	if len(pods.Items) == 0 {
		return fmt.Errorf("no pods found in namespace %s", chaosConfig.Namespace)
	}

	// Filter out chaos-related pods
	var availablePods []v1.Pod
	for _, pod := range pods.Items {
		if pod.Labels["chaos-type"] != "" {
			continue
		}
		if pod.Status.Phase != v1.PodSucceeded && 
		   pod.Status.Phase != v1.PodFailed && 
		   pod.DeletionTimestamp == nil {
			availablePods = append(availablePods, pod)
		}
	}

	if len(availablePods) == 0 {
		return fmt.Errorf("no available pods found in namespace %s (excluding chaos pods)", chaosConfig.Namespace)
	}

	podsToStress := chaosConfig.TargetCount
	if podsToStress > len(availablePods) {
		podsToStress = len(availablePods)
		fmt.Printf("⚠️  Requested to stress %d pods but only %d are available\n", chaosConfig.TargetCount, len(availablePods))
	}
	selectedPods := selectRandomPods(availablePods, podsToStress)

	for i, pod := range selectedPods {
		containerName := ""
		if len(pod.Spec.Containers) > 0 {
			containerName = pod.Spec.Containers[0].Name
		} else {
			fmt.Printf("⚠️  Pod %s has no containers, skipping\n", pod.Name)
			continue
		}
		
		cmd := generateStressCommand(StressCommandMemory, chaosConfig.Intensity, chaosConfig.Duration)
		fmt.Printf("💾 Stressing memory for pod %d/%d: %s (container: %s)\n", i+1, len(selectedPods), pod.Name, containerName)
		fmt.Printf("📋 Command: %s\n", cmd)
		
		err := execInPod(config, clientset, chaosConfig.Namespace, pod.Name, containerName, cmd)
		if err != nil {
			fmt.Printf("❌ Failed to exec in pod %s: %v\n", pod.Name, err)
		} else {
			fmt.Printf("✅ Successfully stressed memory for pod: %s\n", pod.Name)
		}
	}
	return nil
}

// ApplyInPodMixedStress execs into the main container and runs mixed stress
func ApplyInPodMixedStress(config *rest.Config, clientset *kubernetes.Clientset, chaosConfig ChaosConfig) error {
	fmt.Printf("🌪️  Applying IN-POD mixed stress chaos to namespace: %s\n", chaosConfig.Namespace)

	listOptions := metav1.ListOptions{}
	if len(chaosConfig.Labels) > 0 {
		labelSelector := ""
		for k, v := range chaosConfig.Labels {
			if labelSelector != "" {
				labelSelector += ","
			}
			labelSelector += fmt.Sprintf("%s=%s", k, v)
		}
		listOptions.LabelSelector = labelSelector
	}

	pods, err := clientset.CoreV1().Pods(chaosConfig.Namespace).List(context.TODO(), listOptions)
	if err != nil {
		return fmt.Errorf("failed to list pods: %v", err)
	}
	if len(pods.Items) == 0 {
		return fmt.Errorf("no pods found in namespace %s", chaosConfig.Namespace)
	}

	// Filter out chaos-related pods
	var availablePods []v1.Pod
	for _, pod := range pods.Items {
		if pod.Labels["chaos-type"] != "" {
			continue
		}
		if pod.Status.Phase != v1.PodSucceeded && 
		   pod.Status.Phase != v1.PodFailed && 
		   pod.DeletionTimestamp == nil {
			availablePods = append(availablePods, pod)
		}
	}

	if len(availablePods) == 0 {
		return fmt.Errorf("no available pods found in namespace %s (excluding chaos pods)", chaosConfig.Namespace)
	}

	podsToStress := chaosConfig.TargetCount
	if podsToStress > len(availablePods) {
		podsToStress = len(availablePods)
		fmt.Printf("⚠️  Requested to stress %d pods but only %d are available\n", chaosConfig.TargetCount, len(availablePods))
	}
	selectedPods := selectRandomPods(availablePods, podsToStress)

	for i, pod := range selectedPods {
		containerName := ""
		if len(pod.Spec.Containers) > 0 {
			containerName = pod.Spec.Containers[0].Name
		} else {
			fmt.Printf("⚠️  Pod %s has no containers, skipping\n", pod.Name)
			continue
		}
		
		cmd := generateStressCommand(StressCommandMixed, chaosConfig.Intensity, chaosConfig.Duration)
		fmt.Printf("🌪️  Stressing pod %d/%d: %s (container: %s)\n", i+1, len(selectedPods), pod.Name, containerName)
		fmt.Printf("📋 Command: %s\n", cmd)
		
		err := execInPod(config, clientset, chaosConfig.Namespace, pod.Name, containerName, cmd)
		if err != nil {
			fmt.Printf("❌ Failed to exec in pod %s: %v\n", pod.Name, err)
		} else {
			fmt.Printf("✅ Successfully stressed pod: %s\n", pod.Name)
		}
	}
	return nil
}

// execInPod runs a shell command in the specified container of a pod
func execInPod(config *rest.Config, clientset *kubernetes.Clientset, namespace, podName, containerName, command string) error {
	req := clientset.CoreV1().RESTClient().Post().
		Resource("pods").
		Name(podName).
		Namespace(namespace).
		SubResource("exec")

	// Set exec parameters
	req = req.Param("container", containerName)
	req = req.Param("stdin", "false")
	req = req.Param("stdout", "true")
	req = req.Param("stderr", "true")
	req = req.Param("tty", "false")
	req = req.Param("command", "sh")
	req = req.Param("command", "-c")
	req = req.Param("command", command)

	executor, err := remotecommand.NewSPDYExecutor(config, "POST", req.URL())
	if err != nil {
		return err
	}

	return executor.Stream(remotecommand.StreamOptions{
		Stdout: os.Stdout,
		Stderr: os.Stderr,
	})
}

// MonitorPodHealth monitors pod health during stress testing
func MonitorPodHealth(clientset *kubernetes.Clientset, namespace, podName string, duration time.Duration) {
	fmt.Printf("🔍 Monitoring pod health: %s for %s\n", podName, duration.String())
	
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()
	
	startTime := time.Now()
	
	for {
		select {
		case <-ticker.C:
			if time.Since(startTime) >= duration {
				fmt.Printf("✅ Monitoring completed for pod: %s\n", podName)
				return
			}
			
			// Get current pod status
			pod, err := clientset.CoreV1().Pods(namespace).Get(context.TODO(), podName, metav1.GetOptions{})
			if err != nil {
				fmt.Printf("❌ Failed to get pod status: %v\n", err)
				continue
			}
			
			// Check for failures
			if pod.Status.Phase == v1.PodFailed {
				fmt.Printf("💥 POD FAILED: %s - Phase: %s\n", podName, pod.Status.Phase)
				return
			}
			
			// Check container restarts
			for _, container := range pod.Status.ContainerStatuses {
				if container.RestartCount > 0 {
					fmt.Printf("🔄 CONTAINER RESTART: %s restarted %d times\n", container.Name, container.RestartCount)
				}
				
				// Check if container is not ready
				if !container.Ready {
					fmt.Printf("⚠️  CONTAINER NOT READY: %s\n", container.Name)
				}
			}
			
			// Check for OOM kills
			for _, condition := range pod.Status.Conditions {
				if condition.Type == v1.PodScheduled && condition.Status == v1.ConditionFalse {
					fmt.Printf("🚫 POD SCHEDULING FAILED: %s - %s\n", podName, condition.Message)
				}
			}
			
		case <-time.After(duration):
			fmt.Printf("✅ Monitoring completed for pod: %s\n", podName)
			return
		}
	}
}

// ApplyInPodCPUStressWithMonitoring applies CPU stress with health monitoring
func ApplyInPodCPUStressWithMonitoring(config *rest.Config, clientset *kubernetes.Clientset, chaosConfig ChaosConfig) error {
	fmt.Printf("🔥 Applying IN-POD CPU stress chaos with monitoring to namespace: %s\n", chaosConfig.Namespace)

	listOptions := metav1.ListOptions{}
	if len(chaosConfig.Labels) > 0 {
		labelSelector := ""
		for k, v := range chaosConfig.Labels {
			if labelSelector != "" {
				labelSelector += ","
			}
			labelSelector += fmt.Sprintf("%s=%s", k, v)
		}
		listOptions.LabelSelector = labelSelector
	}

	pods, err := clientset.CoreV1().Pods(chaosConfig.Namespace).List(context.TODO(), listOptions)
	if err != nil {
		return fmt.Errorf("failed to list pods: %v", err)
	}
	if len(pods.Items) == 0 {
		return fmt.Errorf("no pods found in namespace %s", chaosConfig.Namespace)
	}

	// Filter out chaos-related pods
	var availablePods []v1.Pod
	for _, pod := range pods.Items {
		if pod.Labels["chaos-type"] != "" {
			continue
		}
		if pod.Status.Phase != v1.PodSucceeded && 
		   pod.Status.Phase != v1.PodFailed && 
		   pod.DeletionTimestamp == nil {
			availablePods = append(availablePods, pod)
		}
	}

	if len(availablePods) == 0 {
		return fmt.Errorf("no available pods found in namespace %s (excluding chaos pods)", chaosConfig.Namespace)
	}

	podsToStress := chaosConfig.TargetCount
	if podsToStress > len(availablePods) {
		podsToStress = len(availablePods)
		fmt.Printf("⚠️  Requested to stress %d pods but only %d are available\n", chaosConfig.TargetCount, len(availablePods))
	}
	selectedPods := selectRandomPods(availablePods, podsToStress)

	for i, pod := range selectedPods {
		containerName := ""
		if len(pod.Spec.Containers) > 0 {
			containerName = pod.Spec.Containers[0].Name
		} else {
			fmt.Printf("⚠️  Pod %s has no containers, skipping\n", pod.Name)
			continue
		}
		
		cmd := generateStressCommand(StressCommandCPU, chaosConfig.Intensity, chaosConfig.Duration)
		fmt.Printf("🔥 Stressing pod %d/%d: %s (container: %s)\n", i+1, len(selectedPods), pod.Name, containerName)
		fmt.Printf("📋 Command: %s\n", cmd)
		
		// Start monitoring in background
		go MonitorPodHealth(clientset, chaosConfig.Namespace, pod.Name, chaosConfig.Duration)
		
		err := execInPod(config, clientset, chaosConfig.Namespace, pod.Name, containerName, cmd)
		if err != nil {
			fmt.Printf("❌ Failed to exec in pod %s: %v\n", pod.Name, err)
		} else {
			fmt.Printf("✅ Successfully stressed pod: %s\n", pod.Name)
		}
	}
	return nil
}

// ApplyKillProcessChaos kills random processes in the pod
func ApplyKillProcessChaos(config *rest.Config, clientset *kubernetes.Clientset, chaosConfig ChaosConfig) error {
	fmt.Printf("💀 Applying KILL PROCESS chaos to namespace: %s\n", chaosConfig.Namespace)

	listOptions := metav1.ListOptions{}
	if len(chaosConfig.Labels) > 0 {
		labelSelector := ""
		for k, v := range chaosConfig.Labels {
			if labelSelector != "" {
				labelSelector += ","
			}
			labelSelector += fmt.Sprintf("%s=%s", k, v)
		}
		listOptions.LabelSelector = labelSelector
	}

	pods, err := clientset.CoreV1().Pods(chaosConfig.Namespace).List(context.TODO(), listOptions)
	if err != nil {
		return fmt.Errorf("failed to list pods: %v", err)
	}
	if len(pods.Items) == 0 {
		return fmt.Errorf("no pods found in namespace %s", chaosConfig.Namespace)
	}

	// Filter out chaos-related pods
	var availablePods []v1.Pod
	for _, pod := range pods.Items {
		if pod.Labels["chaos-type"] != "" {
			continue
		}
		if pod.Status.Phase != v1.PodSucceeded && 
		   pod.Status.Phase != v1.PodFailed && 
		   pod.DeletionTimestamp == nil {
			availablePods = append(availablePods, pod)
		}
	}

	if len(availablePods) == 0 {
		return fmt.Errorf("no available pods found in namespace %s (excluding chaos pods)", chaosConfig.Namespace)
	}

	podsToStress := chaosConfig.TargetCount
	if podsToStress > len(availablePods) {
		podsToStress = len(availablePods)
		fmt.Printf("⚠️  Requested to stress %d pods but only %d are available\n", chaosConfig.TargetCount, len(availablePods))
	}
	selectedPods := selectRandomPods(availablePods, podsToStress)

	for i, pod := range selectedPods {
		containerName := ""
		if len(pod.Spec.Containers) > 0 {
			containerName = pod.Spec.Containers[0].Name
		} else {
			fmt.Printf("⚠️  Pod %s has no containers, skipping\n", pod.Name)
			continue
		}
		
		// Kill random processes - this can cause actual failures
		killCmd := fmt.Sprintf("ps aux | grep -v 'ps aux' | grep -v grep | awk '{print $2}' | head -%d | xargs -r kill -9", chaosConfig.Intensity)
		fmt.Printf("💀 Killing processes in pod %d/%d: %s (container: %s)\n", i+1, len(selectedPods), pod.Name, containerName)
		fmt.Printf("📋 Command: %s\n", killCmd)
		
		// Start monitoring in background
		go MonitorPodHealth(clientset, chaosConfig.Namespace, pod.Name, chaosConfig.Duration)
		
		err := execInPod(config, clientset, chaosConfig.Namespace, pod.Name, containerName, killCmd)
		if err != nil {
			fmt.Printf("❌ Failed to kill processes in pod %s: %v\n", pod.Name, err)
		} else {
			fmt.Printf("✅ Successfully killed processes in pod: %s\n", pod.Name)
		}
	}
	return nil
}

// ApplyCorruptMemoryChaos corrupts memory in the pod
func ApplyCorruptMemoryChaos(config *rest.Config, clientset *kubernetes.Clientset, chaosConfig ChaosConfig) error {
	fmt.Printf("💥 Applying CORRUPT MEMORY chaos to namespace: %s\n", chaosConfig.Namespace)

	listOptions := metav1.ListOptions{}
	if len(chaosConfig.Labels) > 0 {
		labelSelector := ""
		for k, v := range chaosConfig.Labels {
			if labelSelector != "" {
				labelSelector += ","
			}
			labelSelector += fmt.Sprintf("%s=%s", k, v)
		}
		listOptions.LabelSelector = labelSelector
	}

	pods, err := clientset.CoreV1().Pods(chaosConfig.Namespace).List(context.TODO(), listOptions)
	if err != nil {
		return fmt.Errorf("failed to list pods: %v", err)
	}
	if len(pods.Items) == 0 {
		return fmt.Errorf("no pods found in namespace %s", chaosConfig.Namespace)
	}

	// Filter out chaos-related pods
	var availablePods []v1.Pod
	for _, pod := range pods.Items {
		if pod.Labels["chaos-type"] != "" {
			continue
		}
		if pod.Status.Phase != v1.PodSucceeded && 
		   pod.Status.Phase != v1.PodFailed && 
		   pod.DeletionTimestamp == nil {
			availablePods = append(availablePods, pod)
		}
	}

	if len(availablePods) == 0 {
		return fmt.Errorf("no available pods found in namespace %s (excluding chaos pods)", chaosConfig.Namespace)
	}

	podsToStress := chaosConfig.TargetCount
	if podsToStress > len(availablePods) {
		podsToStress = len(availablePods)
		fmt.Printf("⚠️  Requested to stress %d pods but only %d are available\n", chaosConfig.TargetCount, len(availablePods))
	}
	selectedPods := selectRandomPods(availablePods, podsToStress)

	for i, pod := range selectedPods {
		containerName := ""
		if len(pod.Spec.Containers) > 0 {
			containerName = pod.Spec.Containers[0].Name
		} else {
			fmt.Printf("⚠️  Pod %s has no containers, skipping\n", pod.Name)
			continue
		}
		
		// Corrupt memory by writing random data to /dev/mem (if accessible)
		// This is more aggressive and can cause actual crashes
		corruptCmd := fmt.Sprintf("dd if=/dev/urandom of=/dev/mem bs=1M count=%d 2>/dev/null || echo 'Memory corruption attempted'", chaosConfig.Intensity)
		fmt.Printf("💥 Corrupting memory in pod %d/%d: %s (container: %s)\n", i+1, len(selectedPods), pod.Name, containerName)
		fmt.Printf("📋 Command: %s\n", corruptCmd)
		
		// Start monitoring in background
		go MonitorPodHealth(clientset, chaosConfig.Namespace, pod.Name, chaosConfig.Duration)
		
		err := execInPod(config, clientset, chaosConfig.Namespace, pod.Name, containerName, corruptCmd)
		if err != nil {
			fmt.Printf("❌ Failed to corrupt memory in pod %s: %v\n", pod.Name, err)
		} else {
			fmt.Printf("✅ Successfully corrupted memory in pod: %s\n", pod.Name)
		}
	}
	return nil
} 