# Snyk dependency resolution demo app

Demo app that reproduces wrong dependency resolution by Snyk.

## Build all the modules

```
mvn clean install
```

## Build docker image

In root directory:

```
docker build -t pkotrackunit/snyk-demo:latest .
```

## Show app dependency tree

```
cd app
mvn dependency:tree -Dverbose
```

Relevant fragment:

```
[INFO] com.example.snyk.deps.resolution.demo:app:jar:0.0.1-SNAPSHOT
[INFO] +- com.example.snyk.deps.resolution.demo:nested-dep-a:jar:0.0.1-SNAPSHOT:compile
[INFO] |  \- com.example.snyk.deps.resolution.demo:nested-dep-b:jar:0.0.1-SNAPSHOT:compile
[INFO] |     \- (com.google.protobuf:protobuf-java:jar:3.23.2:compile - omitted for conflict with 3.13.0)
[INFO] \- org.jsmart:zerocode-tdd:jar:1.3.33:test
[INFO]    +- com.google.protobuf:protobuf-java:jar:3.13.0:compile
[INFO]    \- com.google.protobuf:protobuf-java-util:jar:3.13.0:test
[INFO]       +- (com.google.protobuf:protobuf-java:jar:3.13.0:test - omitted for duplicate)
```

DOT output:

```
cd app
mvn dependency:tree -DoutputType=dot
```

Also includes the older version:

```
[INFO]  "org.jsmart:zerocode-tdd:jar:1.3.33:test" -> "com.google.protobuf:protobuf-java:jar:3.13.0:compile" ; 
```

`protobuf-java` is transitive dependency of two other libraries with two different versions.

The first library `nested-dep-b` has `compile` scope and includes newer, not vulnerable protobuf-java v3.23.2.
The second library `zerocode-tdd` has `test` scope and includes vulnerable protobuf-java v3.13.0.

Newer version of `protobuf-java` "lost" to older one, due to being deeper in the tree.
This is known and expected.

## Check fat JAR

```
unzip -l app/target/app-0.0.1-SNAPSHOT.jar
```

The JAR has `BOOT-INF/lib/protobuf-java-3.13.0.jar`

## Perform Snyk scan

```
cd app
snyk test
```

Output:

```
Testing /<redacted>/app...

Organization:      trackunit
Package manager:   maven
Target file:       pom.xml
Project name:      com.example.snyk.deps.resolution.demo:app
Open source:       no
Project path:      /<redacted>/app
Licenses:          enabled

✔ Tested 2 dependencies for known issues, no vulnerable paths found.
```

## Scan container

```
snyk container test pkotrackunit/snyk-demo:latest
```

Output:

```
Testing pkotrackunit/snyk-demo:latest...

Organization:      trackunit
Package manager:   apk
Project name:      docker-image|pkotrackunit/snyk-demo
Docker image:      pkotrackunit/snyk-demo:latest
Platform:          linux/arm64
Licenses:          enabled

✔ Tested 15 dependencies for known issues, no vulnerable paths found.

-------------------------------------------------------

Testing pkotrackunit/snyk-demo:latest...

Tested 5 dependencies for known issues, found 3 issues.


Issues to fix by upgrading:

  Upgrade com.google.protobuf:protobuf-java@3.13.0 to com.google.protobuf:protobuf-java@3.16.3 to fix
  ✗ Denial of Service (DoS) [Medium Severity][https://security.snyk.io/vuln/SNYK-JAVA-COMGOOGLEPROTOBUF-3040284] in com.google.protobuf:protobuf-java@3.13.0
    introduced by com.google.protobuf:protobuf-java@3.13.0
  ✗ Denial of Service (DoS) [High Severity][https://security.snyk.io/vuln/SNYK-JAVA-COMGOOGLEPROTOBUF-3167772] in com.google.protobuf:protobuf-java@3.13.0
    introduced by com.google.protobuf:protobuf-java@3.13.0
  ✗ Denial of Service (DoS) [High Severity][https://security.snyk.io/vuln/SNYK-JAVA-COMGOOGLEPROTOBUF-2331703] in com.google.protobuf:protobuf-java@3.13.0
    introduced by com.google.protobuf:protobuf-java@3.13.0



Organization:      trackunit
Package manager:   maven
Target file:       /
Project name:      pkotrackunit/snyk-demo:latest:/
Docker image:      pkotrackunit/snyk-demo:latest
Licenses:          enabled

Snyk wasn’t able to auto detect the base image, use `--file` option to get base image remediation advice.
Example: $ snyk container test pkotrackunit/snyk-demo:latest --file=path/to/Dockerfile

Snyk found some vulnerabilities in your image applications (Snyk searches for these vulnerabilities by default). See https://snyk.co/app-vulns for more information.

To remove these messages in the future, please run `snyk config set disableSuggestions=true`


Tested 2 projects, 1 contained vulnerable paths.
```

## Change scope of zerocode-tdd and rescan

Just for debugging, in [app/pom.xml](app/pom.xml) change scope of `zerocode-tdd` to `compile`:
```
<dependency>
    <groupId>org.jsmart</groupId>
    <artifactId>zerocode-tdd</artifactId>
    <version>1.3.33</version>
    <scope>compile</scope>
</dependency>
```

rescan the project:

```
cd app
snyk test
```

and now the vulnerabilities are detected:

```
Testing /<redacted>/app...

Tested 85 dependencies for known issues, found 59 issues, 59 vulnerable paths.


Issues with no direct upgrade or patch:
  ...
  ✗ Denial of Service (DoS) [High Severity][https://security.snyk.io/vuln/SNYK-JAVA-COMGOOGLEPROTOBUF-2331703] in com.google.protobuf:protobuf-java@3.13.0
    introduced by org.jsmart:zerocode-tdd@1.3.33 > com.google.protobuf:protobuf-java@3.13.0
  This issue was fixed in versions: 3.16.1, 3.18.2, 3.19.2
  ✗ Denial of Service (DoS) [Medium Severity][https://security.snyk.io/vuln/SNYK-JAVA-COMGOOGLEPROTOBUF-3040284] in com.google.protobuf:protobuf-java@3.13.0
    introduced by org.jsmart:zerocode-tdd@1.3.33 > com.google.protobuf:protobuf-java@3.13.0
  This issue was fixed in versions: 3.16.3, 3.19.6, 3.20.3, 3.21.7
  ✗ Denial of Service (DoS) [High Severity][https://security.snyk.io/vuln/SNYK-JAVA-COMGOOGLEPROTOBUF-3167772] in com.google.protobuf:protobuf-java@3.13.0
    introduced by org.jsmart:zerocode-tdd@1.3.33 > com.google.protobuf:protobuf-java@3.13.0
  This issue was fixed in versions: 3.16.3, 3.19.6, 3.20.3, 3.21.7
  ...

Organization:      trackunit
Package manager:   maven
Target file:       pom.xml
Project name:      com.example.snyk.deps.resolution.demo:app
Open source:       no
Project path:      /<redacted>/app
Licenses:          enabled
```
