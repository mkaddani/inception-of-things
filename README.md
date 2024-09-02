# Inception-of-things
## Part 1: K3s and Vagrant
### Terminology
- A **virtual machine** is a computing node that runs within a software process that mimics the
behavior of a physical computer. The software process (often called a hypervisor) provides
infrastructure to virtual machines such as computing power (CPU), memory (RAM), and
interfaces to external resources (such as networking interfaces and physical (disk) storage).
- A **host machine** is a computer that runs a hypervisor to host virtual machines. A host machine
will, most likely, run one of [two types of hypervisor](https://phoenixnap.com/kb/what-is-hypervisor-type-1-2):
    - A **Type 1** hypervisor that runs natively on host machine hardware. A Type 1 hypervisor
    does not require a separate operating system; the hypervisor itself controls access
    to physical resources and shares them between hosted virtual environments. Most
    modern shared virtual environments are Type 1 hypervisors (common examples
    include VMware ESX/ESXi, Oracle VM Server, and some versions of Microsoft
    Hyper-V). These environments are typically installed as shared resources that define
    server infrastructure or other shared resources.
    - A **Type 2** hypervisor is a software that runs on top of a traditional operating system.
    In this case, the hypervisor uses the underlying operating system to control (or
    define) resources and gain access to resources. Most use cases for Vagrant use
    Type 2 hypervisors as host environments for virtual machines and this will be
    the environment that will be used throughout this book. The two common Type 2
    hypervisors are Oracle VirtualBox and the VMware Workstation / Fusion family of
    software. We'll take a look at these products later on in this chapter.
- A **guest machine** is a virtual machine that runs within the hypervisor. The machines that we
will define with Vagrant are guest machines that operate within the environment controlled
by our hypervisor. Guest machines are often entirely different operating systems and
environments from the host environment—something we can definitely use to our advantage
when developing software to be executed on a different environment from our host. (For
example, a developer can write software within a Linux environment that runs on a Windows
host or vice versa.)
- **Vagrant:** is a tool that allows you to define and manage virtual environments using code. It utilizes a single file, known as a `Vagrantfile`, to configure a virtual machine and set up provisioning actions to prepare the environment. Vagrant operates by running these Vagrantfiles on top of pre-packaged operating system images called boxes. Both the Vagrant code and box files can be versioned and distributed, similar to source control in software development.
- **K3s:** K3s is a lightweight Kubernetes distribution created by Rancher Labs, and it is fully certified by the Cloud Native Computing Foundation (CNCF). K3s is highly available and production-ready. It has a very small binary size and very low resource requirements.

In simple terms, K3s is Kubernetes with bloat stripped out and a different backing datastore. That said, it is important to note that K3s is not a fork, as it doesn’t change any of the core Kubernetes functionalities and remains close to stock Kubernetes.

### Vagrantfile

This `Vagrantfile` defines two virtual machines:

1. **mkaddaniS**: This is the Kubernetes master node. It uses the `debian/bullseye64` box and is assigned the IP `192.168.56.110`.
2. **mkaddaniSW**: This is the Kubernetes worker node. It also uses the `debian/bullseye64` box and is assigned the `IP 192.168.56.111`.

The VirtualBox provider is configured with 1024MB of memory and 1 CPU for both VMs.

```Ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Machine 1 (mkaddaniServer) its the Master.
  config.vm.define "mkaddaniS" do |mkaddaniS|
    mkaddaniS.vm.hostname = "mkaddaniS"
    mkaddaniS.vm.box = "debian/bullseye64"
    mkaddaniS.vm.network :private_network, ip: "192.168.56.110",  auto_config: false
    mkaddaniS.vm.provision "shell", path: "./scripts/server_setup.sh"
  end

  # Machine 2 (mkaddaniServerWorker) its the Worker or the agent.
  config.vm.define "mkaddaniSW" do |mkaddaniSW|
    mkaddaniSW.vm.hostname = "mkaddaniSW"
    mkaddaniSW.vm.box = "debian/bullseye64"
    mkaddaniSW.vm.network :private_network, ip: "192.168.56.111", auto_config: false
    mkaddaniSW.vm.provision "shell", path: "./scripts/serverworker_setup.sh"

  end


  # Hypervisor Type2 Provider and settings - General on All the Above Machines:
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "2024"
    vb.cpus = 1
 end
end

```
> ⚠️ The 42 subject advises adjusting the Vagrant configuration to allocate a maximum of 1024MB of RAM. However, this allocation is insufficient for running K3s, resulting in timeout errors. To resolve this, I increased the RAM allocation to 2048MB, and it worked fine.

### K3S setup
The provided `Vagrantfile` automates the creation of the Kubernetes cluster, including installing K3s on the master node and the agent on the worker node. However, an issue was encountered where the worker node could not connect to the master node due to conflicting IP addresses.

- The solution was to add the `--node-ip`, `--bind-address`, and `--advertise-address` flags when installing K3s to ensure the correct IP addresses are used for communication between the nodes.
- The [Answer](https://stackoverflow.com/questions/65995056/kubernetes-api-server-bind-address-vs-advertise-address#:~:text=%2D%2Dadvertise%2Daddress%20ip%20The,default%20interface%20will%20be%20used) includes an explanation of the `--bind-address` and `--advertise-address` flags, their defaults, and their purpose in Kubernetes API server configuration.

### Networking and eth1

You don't strictly need an additional network interface like `eth1` for setting up a K3s cluster with Vagrant. The reason for specifying a dedicated IP address on `eth1` in the given instructions is likely to simulate a separate network interface for the cluster communication.

In a typical Vagrant setup, the virtual machines are connected through a virtual NAT network by default, which allows them to communicate with each other and access the host machine. This virtual network usually works fine for setting up a K3s cluster without any additional configuration.

However, the instructions you provided seem to be emulating a scenario where the K3s cluster nodes (Server and ServerWorker) are connected through a separate network interface (`eth1`) with dedicated IP addresses (`192.168.56.110` and `192.168.56.111`). This could be a way to mimic a more realistic network setup, where the cluster nodes are connected through a dedicated network interface, separate from the default NAT network used for other purposes.

While not strictly necessary for a basic K3s cluster setup with Vagrant, specifying a dedicated network interface and IP addresses can be useful in the following situations:

1. **Learning purposes**: It allows you to practice configuring networking settings, which can be beneficial for understanding more complex network setups in production environments.
2. **Simulating real-world scenarios**: In production environments, it's common to have separate network interfaces and IP addresses for different purposes, such as management, cluster communication, and external traffic. Configuring a dedicated network interface in Vagrant can help simulate these scenarios.
3. **Network isolation**: By using a separate network interface, you can isolate the cluster communication from other network traffic, which can be useful for security or performance reasons.

> ✅ I used a YAML configuration file (instead of ENVs), based on the documentation [here](https://docs.k3s.io/installation/configuration#configuration-file) , to organize my K3s installation according to best practices.

### Demonstration:
- In the **p1** directory, execute the command ```vagrant up```. This will start the virtual machines defined in the Vagrantfile located in that directory.
- Use Vagrant to SSH into both virtual machines using `` vagrant ssh mkaddaniS``.
- To Verify that the ``eth1`` interface has the necessary IP addresses by using the command:
```bash
$> /sbin/ifconfig eth1
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.56.110  netmask 255.255.255.0  broadcast 192.168.56.255
        inet6 fe80::a00:27ff:fe52:8851  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:52:88:51  txqueuelen 1000  (Ethernet)
        RX packets 3434  bytes 507414 (495.5 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 3671  bytes 1709086 (1.6 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```
- To check the hostname on both machines, you can use the following command:
```bash
$> hostname
mkaddaniS
$> hostnamectl
   Static hostname: mkaddaniS
         Icon name: computer-vm
           Chassis: vm
        Machine ID: 1a4fc5f996ea487c9ebcd0db3eb7b286
           Boot ID: a82936d2444c4c459496c47fc9bb0141
    Virtualization: oracle
  Operating System: Debian GNU/Linux 11 (bullseye)
            Kernel: Linux 5.10.0-28-amd64
      Architecture: x86-64
```
- To check if both virtual machines are using K3s, you can use the following commands:
```bash
$> k3s --version
k3s version v1.30.3+k3s1 (f6466040)
go version go1.22.5
$> sudo systemctl status k3s
● k3s.service - Lightweight Kubernetes
     Loaded: loaded (/etc/systemd/system/k3s.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-08-05 11:58:37 UTC; 43min ago
     [......]
```
- Or just use ``kubectl get nodes -o wide``
```bash
NAME         STATUS   ROLES                  AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
mkaddanis    Ready    control-plane,master   46m   v1.30.3+k3s1   192.168.56.110   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-28-amd64   containerd://1.7.17-k3s1
mkaddanisw   Ready    <none>                 34m   v1.30.3+k3s1   192.168.56.111   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-28-amd64   containerd://1.7.17-k3s1

```
### 🐞 Resolving Common Vagrant/VirtualBox Error
```
osboxes@osboxes:~/Desktop/inception-of-things/p1$ VBoxManage --version
WARNING: The vboxdrv kernel module is not loaded. Either there is no module
         available for the current kernel (5.10.0-30-amd64) or it failed to
         load. Please recompile the kernel module and install it by

           sudo /sbin/vboxconfig

         You will not be able to start VMs until this problem is fixed.
6.1.50r161033
osboxes@osboxes:~/Desktop/inception-of-things/p1$            sudo /sbin/vboxconfig
vboxdrv.sh: Stopping VirtualBox services.
vboxdrv.sh: Starting VirtualBox services.
vboxdrv.sh: Building VirtualBox kernel modules.
This system is currently not set up to build kernel modules.
Please install the Linux kernel "header" files matching the current kernel
for adding new hardware support to the system.
The distribution packages containing the headers are probably:
    linux-headers-amd64 linux-headers-5.10.0-30-amd64
This system is currently not set up to build kernel modules.
Please install the Linux kernel "header" files matching the current kernel
for adding new hardware support to the system.
The distribution packages containing the headers are probably:
    linux-headers-amd64 linux-headers-5.10.0-30-amd64

There were problems setting up VirtualBox.  To re-start the set-up process, run
  /sbin/vboxconfig
as root.  If your system is using EFI Secure Boot you may need to sign the
kernel modules (vboxdrv, vboxnetflt, vboxnetadp, vboxpci) before you can load
them. Please see your Linux system's documentation for more information.
```
- If you encounter this error, shut down the machine, go to ``System -> Processor, and enable the "Enable Nested VT-x/AMD-V"`` option. Then, start the machine and run the following command:
```sh
sudo apt install --reinstall linux-headers-$(uname -r)
```
- After that, restart the machine, and it should work fine. [Source](https://askubuntu.com/questions/1487548/trouble-getting-virtualbox-to-work-on-ubuntu-22-04-vxboxdrv-kernel-module-is-no).

## Part 2: K3s and three simple applications
### Terminology
- **Pods**: serve as an abstraction layer in Kubernetes, simplifying the management of various workload types. They allow you to run containers, virtual machines (VMs), serverless functions, and WebAssembly (Wasm) applications without Kubernetes needing to distinguish between them. This abstraction benefits both Kubernetes and the workloads:
  - For Kubernetes: It can concentrate on deploying and managing Pods without concern for their internal contents.
  - For Workloads: Different types of workloads can coexist on the same cluster, utilizing the full capabilities of the declarative Kubernetes API and benefiting from all the features that Pods provide.
- **ReplicaSet**: A ReplicaSet's purpose is to maintain a stable set of replica Pods running at any given time. As such, it is often used to guarantee the availability of a specified number of identical Pods.

- **Deployments**: are the preferred method for running stateless applications on Kubernetes, offering features such as self-healing, scaling, rollouts, and rollbacks. Here's a summarized definition:

  A Deployment manages one or more identical Pods, ensuring they are running as specified. It wraps Pods in a higher-level controller that handles various lifecycle aspects:

  - Self-Healing: If a Pod fails, the Deployment controller automatically replaces it with a new one.
  - Scaling: The Deployment controller can increase or decrease the number of Pods based on demand.
  - Rollouts and Rollbacks: When updating the application, the Deployment controller handles replacing old Pods with new ones. If an update fails, it can roll back to the previous version.

- **Services**: In Kubernetes, a Service is a method for exposing a network application that is running as one or more Pods in your cluster.

  - A key aim of Services in Kubernetes is that you don't need to modify your existing application to use an unfamiliar service discovery mechanism. You can run code in Pods, whether this is a code designed for a cloud-native world, or an older app you've containerized. You use a Service to make that set of Pods available on the network so that clients can interact with it.
  - Pods are unreliable, and you should never connect to them directly. You should always
connect to them through a Service.

- **Ingress**: exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource.

### Kubernetes and Docker

1. **Early Kubernetes Versions and Docker**
    - Kubernetes initially used Docker for container runtime.
    - Docker's drawbacks led to exploration of alternatives.
2. **Container Runtime Interface (CRI)**
    - Introduced to make runtime layer pluggable.
    - Enables choice based on specific needs (e.g., isolation, performance).
3. **Docker Removal and containerd**
    - Kubernetes 1.24 deprecated Docker in favor of containerd.
    - containerd optimized for Kubernetes, adheres to OCI standards.

### Kubernetes Cluster Overview

1. **Kubernetes Cluster Components**
    - **Control Plane Nodes (Master)**
        - Implement Kubernetes intelligence and manage the cluster.
        - Minimum one node required; three to five for high availability.
    - **Worker Nodes (Slave)**
        - Execute user applications.
        - Can be physical servers, VMs, or cloud instances.
        - Support both Linux and Windows.
2. **Control Plane Services**
    - **API Server**
        - Handles API requests and communicates with the cluster.
    - **Scheduler**
        - Assigns workloads to worker nodes based on resource availability.
    - **Controllers**
        - Implement cloud-native features like self-healing and autoscaling.
3. **Application Placement**
    - Development/Testing: User applications may run on control plane nodes.
    - Production: Restrict user applications to worker nodes for stability.

### Ports in Kubernetes

- **nodePort**
    - External traffic port on the node.
- **port**
    - Port of the service within the cluster.
- **targetPort**
    - Port on the pod(s) to which traffic is forwarded.
- **Usage:**
    - External traffic uses `nodePort`.
    - Internal cluster traffic uses `port`.
    - `targetPort` matches the `containerPort` of the pod.
### Demonstration:
- **p2/scripts/server_setup.sh** script sets up a K3s Kubernetes cluster on a virtual machine, configures networking, installs necessary tools, and deploys applications. It begins by updating the system and installing utilities like curl, vim, and net-tools. Then, it configures the network interface with a specified IP address and installs K3s as a server. After waiting for the Kubernetes node to be ready, the script installs the NGINX Ingress Controller and deploys three web applications defined in YAML files. Finally, it applies an Ingress resource to manage external access to the applications.

- **Host file**: It acts as a local DNS (Domain Name System)resolver, mapping domain names to IP addresses
  - The operating system searches the local host table (equivalent of hosts file on the PC) first. If there is not a matching entry in the host table and you have configured a DNS server, the operating system then searches your DNS server

- Running the command ``kubectl get all -o wide`` provides detailed information about all resources in the Kubernetes cluster, including the status of pods, services, deployments, and replicasets.
```bash
$> kubectl get all -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP           NODE        NOMINATED NODE   READINESS GATES
pod/app1-deployment-75cb7c8764-bh54l   1/1     Running   0          48m   10.42.0.12   mkaddanis   <none>           <none>
pod/app2-deployment-9f7ccccc-ph2wn     1/1     Running   0          48m   10.42.0.13   mkaddanis   <none>           <none>
pod/app2-deployment-9f7ccccc-pnlnp     1/1     Running   0          48m   10.42.0.14   mkaddanis   <none>           <none>
pod/app2-deployment-9f7ccccc-vnvbt     1/1     Running   0          48m   10.42.0.15   mkaddanis   <none>           <none>
pod/app3-deployment-5858c9bc5d-sxqn8   1/1     Running   0          48m   10.42.0.16   mkaddanis   <none>           <none>

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   SELECTOR
service/app1-service   ClusterIP   10.43.255.88    <none>        8081/TCP   48m   app=app1
service/app2-service   ClusterIP   10.43.236.250   <none>        8082/TCP   48m   app=app2
service/app3-service   ClusterIP   10.43.116.159   <none>        8083/TCP   48m   app=app3
service/kubernetes     ClusterIP   10.43.0.1       <none>        443/TCP    50m   <none>

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                             SELECTOR
deployment.apps/app1-deployment   1/1     1            1           48m   app1         paulbouwer/hello-kubernetes:1.10   app=app1
deployment.apps/app2-deployment   3/3     3            3           48m   app2         paulbouwer/hello-kubernetes:1.10   app=app2
deployment.apps/app3-deployment   1/1     1            1           48m   app3         paulbouwer/hello-kubernetes:1.10   app=app3

NAME                                         DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                             SELECTOR
replicaset.apps/app1-deployment-75cb7c8764   1         1         1       48m   app1         paulbouwer/hello-kubernetes:1.10   app=app1,pod-template-hash=75cb7c8764
replicaset.apps/app2-deployment-9f7ccccc     3         3         3       48m   app2         paulbouwer/hello-kubernetes:1.10   app=app2,pod-template-hash=9f7ccccc
replicaset.apps/app3-deployment-5858c9bc5d   1         1         1       48m   app3         paulbouwer/hello-kubernetes:1.10   app=app3,pod-template-hash=5858c9bc5d
```

- Running the command ``kubectl get endpoints`` provides information about the endpoints associated with each service in the Kubernetes cluster.
  - **Endpoints:** Lists the IP addresses and ports that correspond to the running pods for each service. For example, app2-service has three endpoints (10.42.0.13:8080, 10.42.0.14:8080, 10.42.0.15:8080), indicating multiple pods are backing this service.

- Running the command ``kubectl describe ingress`` provides detailed information about the Ingress resource in the Kubernetes cluster.

  - Ingress Resource: Named appx-ingress, it is associated with the nginx Ingress controller and handles HTTP traffic for the cluster. The Ingress resource is mapped to the IP address 192.168.56.110.

  - Rules: Defines the routing rules based on the hostnames. For instance, traffic to app1.com is directed to app1-service on port 8081, while app2.com routes to app2-service with multiple backend pods. There is also a wildcard rule (*) that routes unspecified traffic to app3-service.
```bash
$ kubectl describe ingress
Name:             appx-ingress
Labels:           <none>
Namespace:        default
Address:          192.168.56.110
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  app1.com    
              /   app1-service:8081 (10.42.0.12:8080)
  app2.com    
              /   app2-service:8082 (10.42.0.13:8080,10.42.0.14:8080,10.42.0.15:8080)
  app3.com    
              /   app3-service:8083 (10.42.0.16:8080)
  *           
              /   app3-service:8083 (10.42.0.16:8080)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    49m (x3 over 58m)  nginx-ingress-controller  Scheduled for sync

```
![Part2 Chart](https://raw.githubusercontent.com/MkaddaniVogsphere/readme-resources/b1068db0a1163c4311e7d38227fca697683eaa84/IOT.jpg)
## Part 3:  K3d and Argo CD

- **K3d** is a tool for running lightweight Kubernetes clusters in Docker containers, tailored for development and testing scenarios. The setup involves creating a K3d cluster named ``mkaddani-cluster`` with one server and two agent nodes. Ports 80 and 443 are mapped to facilitate HTTP and HTTPS traffic. The cluster is then integrated with the local kubeconfig to ensure kubectl commands operate correctly. Namespaces argocd and dev are created for isolating resources.

- **ArgoCD** is a GitOps tool for continuous delivery on Kubernetes. In this setup, ArgoCD is deployed in the argocd namespace. The installation is performed using a YAML manifest applied via kubectl. ArgoCD is configured to synchronize applications from a Git repository hosted on GitLab. Ingress rules are defined to expose ArgoCD and GitLab services, allowing access through specified hostnames. The YAML files for ArgoCD and the associated ingress resources ensure that applications defined in the Github repository are automatically deployed and managed by ArgoCD, maintaining the desired state as specified in the repository.

![Part3 Chart](https://github.com/MkaddaniVogsphere/readme-resources/blob/9553befcf2ba5ac1a24f60aaba7bc659a3c0b397/IOT-P3.jpg)

## Bonus:  Gitlab

- **GitLab**: was installed using Helm in a K3d Kubernetes cluster. The GitLab Helm chart was added from the official GitLab repository and installed in the gitlab namespace. Key configuration settings included specifying the email for the cert-manager issuer, setting the domain to local.com, and disabling HTTPS. The installation was configured with a timeout of 600 minutes to accommodate the resource-intensive nature of GitLab. Ingress rules were applied to expose GitLab at ``www.gitlab.local.com``, allowing access to the GitLab web interface.

- The repoURL configuration ``http://gitlab-webservice-default.gitlab.svc:8181/root/mkaddani-ops-demo.git`` was used to allow ArgoCD to access the GitLab instance hosted within the same Kubernetes cluster. By specifying the internal service URL and port (``gitlab-webservice-default.gitlab.svc:8181``), ArgoCD can directly communicate with GitLab without needing external network access. This approach ensures secure, efficient interactions between ArgoCD and GitLab, as both are running within the cluster, thus minimizing latency and avoiding potential network issues associated with external connections.


## Resources

### GitOps Cookbook: Kubernetes Automation by Example
**[GitOps Cookbook: Kubernetes Automation by Example](https://www.amazon.com/GitOps-Cookbook-Kubernetes-Automation-Practice/dp/1492097470)**  
This book provides practical examples and techniques for implementing GitOps in Kubernetes environments. It offers insights into automation practices, continuous delivery, and managing Kubernetes clusters using GitOps principles. The guidance in this book was instrumental in setting up and managing the GitOps workflow within the project.

### The Kubernetes Book
**[The Kubernetes Book by Nigel Poulton](https://www.amazon.com/Kubernetes-Book-Nigel-Poulton/dp/1521823634)**  
A comprehensive guide to Kubernetes, covering core concepts, deployment strategies, and advanced topics. This book served as a key resource for understanding Kubernetes architecture, deployment models, and best practices, aiding in the efficient setup and management of Kubernetes clusters for the project.

### Learning Helm: Managing Kubernetes Applications
**[Learning Helm: Managing Kubernetes Applications](https://www.amazon.com/Learning-Helm-Managing-Apps-Kubernetes/dp/1492083658)**  
Focused on Helm, a package manager for Kubernetes, this book provides detailed instructions on managing Kubernetes applications using Helm charts. It was essential for deploying and managing applications within the cluster, facilitating a streamlined process for application management and version control.

