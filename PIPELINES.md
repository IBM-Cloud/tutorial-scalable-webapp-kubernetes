# Pipelines

## Main

_Triggered automatically after the toolchain is created, it deploys the infrastructure using Schematics, builds a container image and deploys the application on the provisioned cluster._

```mermaid
flowchart LR

  manual-listener

  manual-listener-->template

  template
  template-->pipeline
  
  subgraph Listeners
    manual-listener
    template
  end

  pipeline
  pipeline-pvc

  pipeline-->clone-repo

  clone-repo-->deploy-infrastructure
  deploy-infrastructure-->get-infrastructure-output
  clone-repo-->get-app-code
  get-infrastructure-output-->build-app
  get-app-code-->build-app
  build-app-->deploy-app
  deploy-app-->done

  subgraph Pipeline
    pipeline
    pipeline-pvc[(pipeline-pvc)]
  end

  subgraph Tasks
    clone-repo
    deploy-infrastructure
    get-infrastructure-output
    get-app-code
    build-app
    deploy-app
  end
```

## Cleanup

_Triggered manually, it deletes the provisioned resources._

```mermaid
flowchart LR

  manual-cleanup-listener-->cleanup-template
  cleanup-template-->cleanup-pipeline
  
  subgraph Listeners
    manual-cleanup-listener
    cleanup-template
  end

  cleanup-pipeline
  cleanup-pipeline-pvc

  cleanup-pipeline-->cleanup-commands

  cleanup-commands-->done
  
  subgraph Pipeline
    cleanup-pipeline
    cleanup-pipeline-pvc[(cleanup-pipeline-pvc)]
  end

  subgraph Tasks
    cleanup-commands
  end
```