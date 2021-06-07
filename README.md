# MirBFT Research Prototype
The implementation for  [Mir-BFT: High-Throughput Robust BFT for Decentralized Networks
](https://arxiv.org/abs/1906.05552) paper.

## Setup
The following scripts among other dependencies install `Go` in the home directory and set gopath to `/opt/gopath/bin/`.

The default path to the repository is set to: `/opt/gopath/src/github.com/IBM/mirbft/`.


Go to the deployment directory:

`cd deployment`

To install Golang and requirements: 

`./install-local.sh`

To clone the repository under `/opt/gopath/src/github.com/IBM/mirbft/`:

`./clone.sh`

Build the protobufs:

`cd ..`

`./run-protoc.sh`

To compile the node:

`cd server`

`go build`

To compile the client:

`cd client`

`go build`

A node sample configuration exists in `sampleconfig/serverconfig/` .

A client sample configuration exists in `sampleconfig/clientconfig/`.

To start locally a setup with 4 nodes and 1 client:

On each node:

`cd server`

`./server ../sampleconfig/serverconfig/config$id.yml server$id`
where `$id` is `1 2 3 4` for each of the 4 nodes.

The first argument is the path to the node configuration and the second argument a name prefix for a trace file.


On the client:

`cd client`

`./client ../sampleconfig/clientconfig/4peer-config.yml client`

Again, the first argument is the path to the node configuration and the second argument a name prefix for a trace file.


Similarly, to start locally a setup with 1 peer and 1 client:

On the node:

`cd server`

`./server ../sampleconfig/serverconfig/config.yml server`

On the client:

`cd client`

`./client ../sampleconfig/clientconfig/1peer-config.yml client`

## Performance Evaluation

There following steps need to be followed for performance evaluation:
1. clone the repository 

### System requirements
The evaluation was run on dedicated virtual machines:
* 4-100 node machines
* 16 client machines

Each machine:
* 32 vCPUs
* 32 GB memory
* 2 network interfaces (public & private) each 1 Gbps up and down
* 100 GB disk 
* OS: Ubuntu 18.04 

### Running the evaluation
1. Clone the repository on each machine and install the requirements with scripts under `deployment` directory.
2. Generate a certificate authority (CA) key and certificate.
3. Generate a private key and certificate  signed by CA for each server (node).
4. Copy the private key to each server (node).
5. Copy all the certificates to all servers (node).
6. Copy the CA certificate to all clients.
7. Edit the configuration file for each server and client (see details below).
8. Start all clients and source their output to a log file e.g.: `./client ../sampleconfig/clientconfig/config.yml client &> client.log`
9. Start all servers and source their output to a log file e.g.: `./server ../sampleconfig/serverconfig/config.yml server &> server.log`
10. Use the performance evaluation tool to parse the log files and get performance evaluation results (see details below).

Experiment where for few (1-2) minutes or for for few (1-4) million client requests in total.

### Server configuration

Each server has:
 * 2 IPs: `ip-public`, `ip-private`.
 * and id from `0` to `N-1`, where `N` the number of servers.
 * a private key: `server.key`
 * a certificate: `server.pem`
 * 2 listening ports: `server-to-server-port`, `server-to-client-port` such that `server-to-client-port`=`server-to-server-port+2`
 
 Comments in `sampleconfig/serverconfig/config*.yml` files describe how to configure a server.
 
 Importantly:
 
 * `signatureVerification`: must be true to enable client authentication
 * `sigSharding`: must be true to enable signature verification sharding (SVS). Mir by default is considered to have SVS.
 * `payloadSharding`: must be true to enable light total order broadcast (LTO) optimization.
 * `watermarkDist`: should be greater than or equal to `checkpointDist`.
 * `watermarkDist`: should be also greater than or equal to the number of nodes.
 * `bucketRotationPeriod`: should be greater than or equal to `watermarkDist`
 * `clientWatermarkDist`: should be set to a very large value to allow few clients saturate throughput. Otherwise the setup would require many client machines.

 In `self` section:
 * `listen` is always `"0.0.0.0:server-to-server-port"`
 
 In `servers` section:
 * `certFiles` provide them with the same order as the corresponding server's `id`.
 * `addresses`:
    * provide them with the same order as the corresponding server's `id`. 
    * use `ip-private` addresses.
    * make sure the port number `server-to-server-port` matches the port number in the `self` section of each server.
 
### Client configuration
 Comments in `sampleconfig/serverconfig/config*.yml` files describe how to configure a server.

 In `servers` section:
 * `addresses`:
     * provide them with the same order as the corresponding server's `id`. 
     * use `ip-public` addresses.
     * make sure the port number `server-to-client-port` matches the port number in the `self` section of each server increased by `2`.
  

### Latency-Throughput plots
Progressively (different runs) increase the load from clients by increasing `requestRate` until the throughput of the system stops increasing and latency increases significantly.

### Scalability plots
For each number of nodes `N` run a Latency-Throughput plot and peak the maximum throughput.

### Experiments with faults
Configure the servers with the parameters in `Byzantine behavior` section of the configuration.
* To emulate straggler behavior set `ByzantineDelay` to a non-zero value, smaller than `epochTimeoutNsec`.
* To emulate crash faults set `ByzantineDelay` to a large value, greater than `epochTimeoutNsec`.
* To emulate censoring set `censoring` to a non-zero percentage.

### Simulating protocols  without duplication prevention
In `Byzantine behavior` section, set `byzantineDuplication` to true.

### Performance Evaluation Tool
Performance evaluation metrics *throughput* and *latency* can be calculated with the `tools/perf-eval.py` with the logs generated by the `server/server` and `client/client` binaries.

The script should be called as follows:
`python tools/perf-eval.py n m [server_1.out ... server_m.out] [client_1.out ... client_m.out] x y`
* `n`: the number of server log files
* `m`: the number of client log files
* `[server_1.out ... server_m.out]`: list of server files
* `[client_1.out ... client_m.out]`: list of client files
* `x`: number of requests to ignore at the beginning of the experiment for throughput calculation
* `y`: number of requests to ignore at the end of the experiment for throughput calculation

The output of the script is: 
```$xslt
End to end latency: #### ms
Average request rate per client: #### r/s
Experiment duration: #### s
Throughput: #### r/s
Requests: ####
```
Moreover the script generates a file `latency.out` with latency CDF.
