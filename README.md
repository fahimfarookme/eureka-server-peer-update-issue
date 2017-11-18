# The issue of Eureka Server not updating the service-urls upon /refresh

This issue has been discussed [here](https://github.com/spring-cloud/spring-cloud-netflix/issues/2421).

It takes around 10 minutes for Eureka Server to reflect the new service-urls (i.e. `eureka.client.service-url.defaultZone`) after hitting the /refresh endpoint. i.e.
- Started the Eureka server while the config server is UP and running.
- Changed the service-urls in config repo and hit the /refresh endpoint of Eureka Server
- New service-url is not reflected in the eureka dashboard or `PeerEurekaNodes` class as soon as environment is refreshed.


## Solutions
This is because ` PeerEurekaNodes.updatePeerEurekaNodes()` is invoked by a scheduler which runs in every 10 minutes by default. i.e. configured by `EurekaServerConfigBean.peerEurekaNodesUpdateIntervalMs = 10 * MINUTES`. 

Provided that the /refresh endpoint is invoked, waiting for 10 minutes to reflect the service-urls in Eureka Server can lead ASM teams to come to wrong conclusions. Also as I analyzed, we cannot define `EurekaServerContext ` bean in `@RefreshScope`, because that will reinitialize the scheduler objects and results in an IllegalState. 

1. Fix 1 - Setting the property `eureka.server.peer-eureka-nodes-update-interval-ms` to a lower value could solve the problem, however that will introduce unnecessary network traffic in the system since the service-url list is rarely updated. 

3. Fix 2 - I would suggest to call  `PeerEurekaNodes.updatePeerEurekaNodes()` upon `EnvironmentChangeEvent` as a better solution. PR submitted [here] (https://github.com/spring-cloud/spring-cloud-netflix/pull/2455).
