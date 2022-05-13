job("Publish Teamcity Helm chart") {
    container("alpine/helm") {
        shellScript {
            content = """
                export HELM_EXPERIMENTAL_OCI=1
                sed -i.bak "s/^version: 0.1.0/version: 0.1.${'$'}JB_SPACE_EXECUTION_NUMBER/" ./charts/teamcity/Chart.yaml
                helm registry login anshulg.registry.jetbrains.space -u ${'$'}JB_SPACE_CLIENT_ID -p ${'$'}JB_SPACE_CLIENT_SECRET
                helm package ./charts/teamcity
                helm push teamcity-0.1.${'$'}JB_SPACE_EXECUTION_NUMBER.tgz oci://anshulg.registry.jetbrains.space/p/shared/charts
            """.trimIndent()
        }

        resources {
            cpu = 512
            memory = 1950
        }
    }
}