package main

import (
	"context"
	"fmt"
	"math/rand"
	"time"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

// TestPodConfig holds configuration for creating test pods
type TestPodConfig struct {
	Count     int
	Namespace string
	Labels    map[string]string
}

// CreateTestPods creates random test pods for chaos testing
func CreateTestPods(clientset *kubernetes.Clientset, config TestPodConfig) error {
	testImages := []string{
		"nginx:alpine",
		"busybox:latest",
		"alpine:latest",
		"redis:alpine",
		"postgres:alpine",
		"httpd:alpine",
		"mysql:8.0",
		"mongo:latest",
	}

	fmt.Printf("🔧 Creating %d test pods in namespace: %s\n", config.Count, config.Namespace)

	for i := 1; i <= config.Count; i++ {
		podName := fmt.Sprintf("test-pod-%d", i)
		image := testImages[rand.Intn(len(testImages))]
		
		// Merge default labels with user-provided labels
		labels := map[string]string{
			"app":     "chaos-test",
			"created": "chaos-monkey",
		}
		for k, v := range config.Labels {
			labels[k] = v
		}

		pod := &v1.Pod{
			ObjectMeta: metav1.ObjectMeta{
				Name:      podName,
				Namespace: config.Namespace,
				Labels:    labels,
			},
			Spec: v1.PodSpec{
				Containers: []v1.Container{
					{
						Name:  "main",
						Image: image,
						Ports: []v1.ContainerPort{
							{
								ContainerPort: 80,
							},
						},
					},
				},
				RestartPolicy: v1.RestartPolicyAlways,
			},
		}

		_, err := clientset.CoreV1().Pods(config.Namespace).Create(context.TODO(), pod, metav1.CreateOptions{})
		if err != nil {
			fmt.Printf("⚠️  Failed to create test pod %s: %v\n", podName, err)
			return err
		} else {
			fmt.Printf("✅ Created test pod: %s with image: %s\n", podName, image)
		}
	}

	// Wait a bit for pods to be created
	fmt.Println("⏳ Waiting for pods to be ready...")
	time.Sleep(5 * time.Second)
	return nil
}

// CleanupTestPods removes all test pods created by chaos monkey
func CleanupTestPods(clientset *kubernetes.Clientset, namespace string) error {
	fmt.Printf("🧹 Cleaning up test pods in namespace: %s\n", namespace)
	
	pods, err := clientset.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{
		LabelSelector: "created=chaos-monkey",
	})
	if err != nil {
		return fmt.Errorf("failed to list test pods: %v", err)
	}

	for _, pod := range pods.Items {
		fmt.Printf("🗑️  Deleting test pod: %s\n", pod.Name)
		err := clientset.CoreV1().Pods(namespace).Delete(context.TODO(), pod.Name, metav1.DeleteOptions{})
		if err != nil {
			fmt.Printf("⚠️  Failed to delete test pod %s: %v\n", pod.Name, err)
		}
	}

	fmt.Printf("✅ Cleaned up %d test pods\n", len(pods.Items))
	return nil
} 