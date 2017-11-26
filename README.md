The project override some class in maven-scm-provider-gitexe runtime, so to support flatten structure of the parent in release plugin

1. On each pom.xml (including all child and parent projects)
define the scm connection to prevent url realignment
	<scm>
		<url>https://github.com/alfredyctan/afc-maven</url>
		<connection>scm:git:https://github.com/alfredyctan/afc-maven.git</connection>
		<developerConnection>scm:git:https://github.com/alfredyctan/afc-maven.git</developerConnection>
  	<tag>HEAD</tag>
	</scm>

2. add additional dependency in the maven-release-plugin
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-release-plugin</artifactId>
				<version>2.5.3</version>
				<configuration>
					<tagNameFormat>@{project.artifactId}-@{project.version}</tagNameFormat>
					<preparationGoals>clean install</preparationGoals>
					<pushChanges>true</pushChanges>
					<releaseProfiles>release-mode</releaseProfiles>
					<username>${release.username}</username>
					<password>${release.password}</password>
				</configuration>
				<dependencies>
					<dependency>
						<groupId>org.afc.maven.scm</groupId>
						<artifactId>maven-scm-provider-git-flatten</artifactId>
						<version>1.9.4</version>
					</dependency>
				</dependencies>
			</plugin>
