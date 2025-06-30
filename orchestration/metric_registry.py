from sklearn.metrics import (
    accuracy_score,
    f1_score,
    mean_squared_error,
    roc_auc_score,
    precision_score,
)

from orchestration.registries import metric_registry

metric_registry.register(
    name="accuracy",
    func=accuracy_score,
)
metric_registry.register(
    name="f1",
    func=f1_score,
)
metric_registry.register(
    name="mse",
    func=mean_squared_error,
)
metric_registry.register(
    name="roc_auc",
    func=roc_auc_score,
)
metric_registry.register(
    name="precision",
    func=precision_score,
)
