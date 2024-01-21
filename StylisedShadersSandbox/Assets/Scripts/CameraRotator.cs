using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Simple script that rotates the camera every frame whilst active.
/// </summary>
public class CameraRotator : MonoBehaviour
{
	//Variables to assign via the unity inspector.
	[SerializeField] [Range(0.01f, 10.0f)] private float m_rotationSpeed = 0.04f;

	//Functions.
	private void Update() {
		this.transform.forward = Vector3.Slerp(this.transform.forward, this.transform.right, m_rotationSpeed * Time.deltaTime);
	}
}
