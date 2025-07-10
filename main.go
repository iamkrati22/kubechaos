package main

import (
	"context"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"strings"
	"time"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	// Parse command line flags
	var (
		namespace    = flag.String("namespace", "default", "Namespace to operate on")
		labelFilter  = flag.String("labels", "", "Label selector (e.g., 'app=nginx,env=prod')")
		createPods   = flag.Bool("create", false, "Create test pods before chaos")
		podCount     = flag.Int("count", 3, "Number of test pods to create")
		deleteCount  = flag.Int("delete-count", 1, "Number of pods to delete (default: 1)")
		dryRun       = flag.Bool("dry-run", false, "Show what would be deleted without actually deleting")
		cleanup      = flag.Bool("cleanup", false, "Clean up test pods created by chaos monkey")
		chaosType    = flag.String("chaos-type", "pod-delete", "Type of chaos: pod-delete, cpu-stress, memory-stress, in-pod-cpu-stress, in-pod-memory-stress, in-pod-mixed-stress, kill-process, corrupt-memory")
		intensity    = flag.Int("intensity", 5, "Chaos intensity (1-10 scale)")
		duration     = flag.String("duration", "30s", "Duration of chaos (e.g., 30s, 2m, 1h)")
		cronSchedule = flag.String("cron", "", "Cron schedule for periodic chaos (e.g., '*/5 * * * *')")
		probability  = flag.Float64("probability", 0.5, "Probability of chaos trigger (0.0-1.0)")
		help         = flag.Bool("help", false, "Show help message")
		version      = flag.Bool("version", false, "Show version information")
	)
	flag.Parse()

	if *version {
		PrintVersion()
		return
	}

	if *help {
		fmt.Println("🎭 Chaos Monkey - Randomly delete pods in Kubernetes")
		fmt.Println("\nUsage:")
		fmt.Println("  go run main.go [flags]")
		fmt.Println("\nFlags:")
		flag.PrintDefaults()
		fmt.Println("\nExamples:")
		fmt.Println("  go run main.go                                    # Delete random pod in default namespace")
		fmt.Println("  go run main.go -namespace=kube-system             # Delete random pod in kube-system")
		fmt.Println("  go run main.go -labels='app=nginx'                # Delete random pod with app=nginx label")
		fmt.Println("  go run main.go -create -count=5                   # Create 5 test pods then delete one")
		fmt.Println("  go run main.go -delete-count=3                    # Delete 3 random pods")
		fmt.Println("  go run main.go -dry-run                           # Show what would be deleted")
		fmt.Println("  go run main.go -cleanup                           # Clean up all test pods")
		fmt.Println("  go run main.go -chaos-type=cpu-stress             # Apply CPU stress to pods")
		fmt.Println("  go run main.go -chaos-type=memory-stress          # Apply memory stress to pods")
		fmt.Println("  go run main.go -chaos-type=in-pod-cpu-stress      # Apply CPU stress inside pods")
		fmt.Println("  go run main.go -chaos-type=in-pod-memory-stress   # Apply memory stress inside pods")
		fmt.Println("  go run main.go -chaos-type=in-pod-mixed-stress    # Apply mixed stress inside pods")
		fmt.Println("  go run main.go -chaos-type=kill-process           # Kill random processes in pods")
		fmt.Println("  go run main.go -chaos-type=corrupt-memory         # Corrupt memory in pods")
		fmt.Println("  go run main.go -cron='*/5 * * * *'               # Run chaos every 5 minutes")
		fmt.Println("  go run main.go -intensity=8                      # High intensity chaos (1-10)")
		return
	}

	// Initialize random seed
	rand.Seed(time.Now().UnixNano())

	// Get kubeconfig path - handle Windows and Unix paths
	var kubeconfig string
	if os.Getenv("KUBECONFIG") != "" {
		kubeconfig = os.Getenv("KUBECONFIG")
	} else {
		home := os.Getenv("HOME")
		if home == "" {
			home = os.Getenv("USERPROFILE") // Windows fallback
		}
		if home == "" {
			panic("Could not determine home directory")
		}
		kubeconfig = home + "/.kube/config"
	}

	// Build config from kubeconfig
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		panic(fmt.Sprintf("Failed to build config: %v", err))
	}

	// Create clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(fmt.Sprintf("Failed to create clientset: %v", err))
	}

	fmt.Println("🎭 Chaos Monkey Starting...")
	fmt.Printf("📦 Operating in namespace: %s\n", *namespace)

	// Parse duration
	chaosDuration, err := time.ParseDuration(*duration)
	if err != nil {
		panic(fmt.Sprintf("Invalid duration format: %v", err))
	}

	// Handle cleanup mode
	if *cleanup {
		err := CleanupTestPods(clientset, *namespace)
		if err != nil {
			panic(fmt.Sprintf("Failed to cleanup test pods: %v", err))
		}
		
		// Also cleanup chaos jobs
		err = CleanupChaosJobs(clientset, *namespace)
		if err != nil {
			fmt.Printf("Warning: Failed to cleanup chaos jobs: %v\n", err)
		}
		return
	}

	// Handle cron trigger mode
	if *cronSchedule != "" {
		fmt.Printf("⏰ Starting cron chaos trigger with schedule: %s\n", *cronSchedule)
		
		cronConfig := CronTriggerConfig{
			Schedule:    *cronSchedule,
			ChaosType:   ChaosType(*chaosType),
			Probability: *probability,
			MaxDuration: chaosDuration,
		}
		
		StartCronTrigger(clientset, cronConfig)
		
		// Keep the program running for cron triggers
		fmt.Println("🔄 Cron trigger started. Press Ctrl+C to stop...")
		select {} // Wait indefinitely
	}

	// Create test pods if requested
	if *createPods {
		config := TestPodConfig{
			Count:     *podCount,
			Namespace: *namespace,
			Labels:    parseLabels(*labelFilter),
		}
		err := CreateTestPods(clientset, config)
		if err != nil {
			panic(fmt.Sprintf("Failed to create test pods: %v", err))
		}
	}

	// List pods with optional label filter
	listOptions := metav1.ListOptions{}
	if *labelFilter != "" {
		listOptions.LabelSelector = *labelFilter
	}

	pods, err := clientset.CoreV1().Pods(*namespace).List(context.TODO(), listOptions)
	if err != nil {
		panic(fmt.Sprintf("Failed to list pods: %v", err))
	}

	if len(pods.Items) == 0 {
		fmt.Printf("❌ No pods found in namespace: %s", *namespace)
		if *labelFilter != "" {
			fmt.Printf(" with labels: %s", *labelFilter)
		}
		fmt.Println()
		
		if !*createPods {
			fmt.Println("💡 Tip: Use -create flag to create test pods automatically")
		}
		return
	}

	// Filter out pods that are being terminated or are in error state
	var availablePods []v1.Pod
	for _, pod := range pods.Items {
		if pod.Status.Phase != v1.PodSucceeded && 
		   pod.Status.Phase != v1.PodFailed && 
		   pod.DeletionTimestamp == nil {
			availablePods = append(availablePods, pod)
		}
	}

	if len(availablePods) == 0 {
		fmt.Printf("❌ No available pods found")
		if *labelFilter != "" {
			fmt.Printf(" with labels: %s", *labelFilter)
		}
		fmt.Println()
		return
	}

	// Handle different chaos types
	chaosConfig := ChaosConfig{
		Type:        ChaosType(*chaosType),
		Namespace:   *namespace,
		Labels:      parseLabels(*labelFilter),
		Duration:    chaosDuration,
		Intensity:   *intensity,
		TargetCount: *deleteCount,
	}

	switch ChaosType(*chaosType) {
	case ChaosTypePodDelete:
		// Original pod deletion logic
		applyPodDeleteChaos(clientset, availablePods, chaosConfig, *dryRun)
	case ChaosTypeCPUStress:
		ApplyCPUStress(clientset, chaosConfig)
	case ChaosTypeMemoryStress:
		ApplyMemoryStress(clientset, chaosConfig)
	case ChaosTypeInPodCPUStress:
		ApplyInPodCPUStress(config, clientset, chaosConfig)
	case ChaosTypeInPodMemoryStress:
		ApplyInPodMemoryStress(config, clientset, chaosConfig)
	case ChaosTypeInPodMixedStress:
		ApplyInPodMixedStress(config, clientset, chaosConfig)
	case ChaosTypeKillProcess:
		ApplyKillProcessChaos(config, clientset, chaosConfig)
	case ChaosTypeCorruptMemory:
		ApplyCorruptMemoryChaos(config, clientset, chaosConfig)
	default:
		fmt.Printf("⚠️  Unknown chaos type: %s, falling back to pod deletion\n", *chaosType)
		applyPodDeleteChaos(clientset, availablePods, chaosConfig, *dryRun)
	}
}

// selectRandomPods selects random pods without duplicates
func selectRandomPods(pods []v1.Pod, count int) []v1.Pod {
	if count >= len(pods) {
		return pods
	}
	
	// Create a copy of the slice to avoid modifying the original
	podCopy := make([]v1.Pod, len(pods))
	copy(podCopy, pods)
	
	// Fisher-Yates shuffle to get random pods
	selected := make([]v1.Pod, 0, count)
	for i := 0; i < count; i++ {
		// Pick a random index from remaining pods
		randomIndex := rand.Intn(len(podCopy))
		selected = append(selected, podCopy[randomIndex])
		
		// Remove the selected pod from the copy
		podCopy = append(podCopy[:randomIndex], podCopy[randomIndex+1:]...)
	}
	
	return selected
}

// applyPodDeleteChaos applies pod deletion chaos
func applyPodDeleteChaos(clientset *kubernetes.Clientset, availablePods []v1.Pod, config ChaosConfig, dryRun bool) {
	// Determine how many pods to delete
	podsToDelete := config.TargetCount
	if podsToDelete > len(availablePods) {
		podsToDelete = len(availablePods)
		fmt.Printf("⚠️  Requested to delete %d pods but only %d are available\n", config.TargetCount, len(availablePods))
	}

	// Select random pods to delete
	selectedPods := selectRandomPods(availablePods, podsToDelete)

	if dryRun {
		fmt.Println("🔍 DRY RUN MODE - No pods will be deleted")
		fmt.Printf("📋 Would delete %d pods:\n", len(selectedPods))
		for i, pod := range selectedPods {
			fmt.Printf("  %d. %s (Status: %s)\n", i+1, pod.Name, pod.Status.Phase)
		}
		return
	}

	// Delete the selected pods
	deletedPods := []string{}
	for i, pod := range selectedPods {
		fmt.Printf("💀 Deleting pod %d/%d: %s\n", i+1, len(selectedPods), pod.Name)
		err := clientset.CoreV1().Pods(config.Namespace).Delete(context.TODO(), pod.Name, metav1.DeleteOptions{})
		if err != nil {
			fmt.Printf("❌ Failed to delete pod %s: %v\n", pod.Name, err)
		} else {
			deletedPods = append(deletedPods, pod.Name)
		}
	}

	fmt.Printf("✅ Successfully deleted %d/%d pods!\n", len(deletedPods), len(selectedPods))
	fmt.Printf("📊 Summary: Deleted pods %v from namespace '%s'\n", deletedPods, config.Namespace)
}

// parseLabels converts a comma-separated label string to a map
func parseLabels(labelString string) map[string]string {
	labels := make(map[string]string)
	if labelString == "" {
		return labels
	}
	
	pairs := strings.Split(labelString, ",")
	for _, pair := range pairs {
		parts := strings.Split(strings.TrimSpace(pair), "=")
		if len(parts) == 2 {
			labels[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
		}
	}
	return labels
}

 