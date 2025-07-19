using UnityEngine;

public class RayMarchHeightMapController : MonoBehaviour
{
    public Material rayMarchHeightMapMaterial;
    public Transform lightTransform;
    public Transform surfaceTransform;

    private void Update()
    {
        rayMarchHeightMapMaterial.SetVector("_LightLocalPosition", surfaceTransform.InverseTransformPoint(lightTransform.position));
    }
}
