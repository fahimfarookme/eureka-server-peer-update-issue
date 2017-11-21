## Fix 2 - Update peer Eureka nodes on `EnvironmentChangeEvent`

This solution is discussed [here](https://github.com/spring-cloud/spring-cloud-netflix/issues/2421#issuecomment-345305517). Also the PR submitted [here](https://github.com/spring-cloud/spring-cloud-netflix/pull/2455). 

This project is setup in order to  get the Eureka Server tested with 1.4.0.BUILD-SNAPSHOT of spring-cloud-netflix.

The solution is to call `PeerEurekaNodes.updatePeerEurekaNodes()` upon `EnvironmentChangeEvent`. i.e.

```````
@Bean
@ConditionalOnMissingBean
public PeerEurekaNodes peerEurekaNodes(...) {
	return new RefreshablePeerEurekaNodes(...);
}

static class RefreshablePeerEurekaNodes extends PeerEurekaNodes
		implements ApplicationListener<EnvironmentChangeEvent> {
        // constrcutor

	@Override
	public void onApplicationEvent(final EnvironmentChangeEvent event) {
		updatePeerEurekaNodes(resolvePeerUrls());
	}
}

``````

