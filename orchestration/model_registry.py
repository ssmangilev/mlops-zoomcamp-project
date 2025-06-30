from xgboost import XGBClassifier
from sklearn.ensemble import RandomForestClassifier

from orchestration.registries import model_registry


# Register models with the registry
# Note: The model classes should be imported from their respective libraries
# and registered here.
model_registry.register(
    name="XGBClassifier",
    model_class=XGBClassifier)
model_registry.register(
    name="RandomForestClassifier",
    model_class=RandomForestClassifier
)
