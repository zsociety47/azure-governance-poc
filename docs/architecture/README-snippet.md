# Architecture

The diagram shows the target build. The repository so far has created the resource group only. The user, the Reader role, the policy, and the budget are not in Azure yet.

[Governance guardrails on Azure](https://claude.ai/artifact/EK1rNHXFiKMqHgF8VF15Wy)

The operator sets the rules with Terraform. The junior user can look inside one resource group. The policy blocks an expensive virtual machine size before it exists. The budget only sends an alert. It does not stop spending.
