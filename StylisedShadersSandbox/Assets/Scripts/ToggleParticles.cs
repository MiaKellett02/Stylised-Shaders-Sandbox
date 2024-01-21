using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ToggleParticles : MonoBehaviour
{
    [SerializeField] private GameObject particleObject;

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P)) {
            particleObject.SetActive(!particleObject.activeSelf);
        }
    }
}
