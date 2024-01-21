using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

public class FreeMovementCamera : MonoBehaviour {
	#region Variables to assign via the unity inspector (SerializeFields).
	[SerializeField]
	[Range(50.0f, 20000.0f)]
	private float mouseSensitivity = 100.0f;

	[SerializeField]
	[Range(2.0f, 200.0f)]
	private float movementSpeed = 20.0f;

	[SerializeField]
	private GameObject cameraParent = null;

	[SerializeField]
	private Transform forwardPoint = null;

	[SerializeField]
	private Transform rightpoint = null;

	[SerializeField]
	private Transform upPoint = null;
	#endregion

	#region Private Variables.

	private Vector3 xyzRotation = Vector3.zero;
	private float mouseX = 0.0f;
	private float mouseY = 0.0f;
	private float originalSpeed = 0.0f;
	private Vector3 originalRotation = Vector3.zero;

	private Vector3 movement = Vector3.zero;
	#endregion

	#region Private Functions.
	// Start is called before the first frame update
	void Start() {
		originalRotation = transform.rotation.eulerAngles;
		originalSpeed = movementSpeed;
		//Make mouse not appear.
		Cursor.lockState = CursorLockMode.Locked;
		Cursor.visible = false;
	}

	// Update is called once per frame
	void Update() {
		HandleInput();
	}

	private void HandleInput() {
		HandleRotation();
		HandleKeyboardMovement();

		//Reset Rotation.
		if (Input.GetKey(KeyCode.R)) {
			transform.localRotation = quaternion.Euler(originalRotation);
		}
	}

	private void HandleRotation() {
		//The variable mouseX and mouseY get the mouse input, times it by the mouse sensitivity and time.deltatime to get how much the camera should turn by.
		mouseX = Input.GetAxis("Mouse X") * mouseSensitivity * Time.deltaTime;
		mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity * Time.deltaTime;

		//xRotation limits the amounnt the player can look up or down to 90 degrees in both directions.
		xyzRotation.x -= mouseY;
		xyzRotation.x = Mathf.Clamp(xyzRotation.x, -90.0f, 90.0f);

		//yRotation is looking left or right.
		xyzRotation.y += mouseX;

		//This actually moves the player characters camera and movement.
		transform.Rotate(Vector3.right * -mouseY);
		transform.Rotate(Vector3.up * mouseX);

		//Roll Rotation.
		if (Input.GetKey(KeyCode.Q)) {
			transform.Rotate(Vector3.forward, ((mouseSensitivity * Time.deltaTime) / 2.0f));
		}
		if (Input.GetKey(KeyCode.E)) {
			transform.Rotate(Vector3.forward, ((-mouseSensitivity * Time.deltaTime) / 2.0f));
		}

	}

	private void HandleKeyboardMovement() {
		// Forward/Back/Left/Right/Up/Down movement.
		movement = Vector3.zero;

		//Local Axis.
		Vector3 localForward = CalculateVectorFromCameraToTarget(forwardPoint);
		Vector3 localRight = CalculateVectorFromCameraToTarget(rightpoint);
		Vector3 localUp = CalculateVectorFromCameraToTarget(upPoint);

		//Get the input.
		if (Input.GetKey(KeyCode.LeftShift)) {
			movementSpeed = originalSpeed * 2;
		} else {
			movementSpeed = originalSpeed;
		}

		if (Input.GetKey(KeyCode.W)) {
			movement += localForward;
		}
		if (Input.GetKey(KeyCode.S)) {
			movement -= localForward;
		}
		if (Input.GetKey(KeyCode.A)) {
			movement -= localRight;
		}
		if (Input.GetKey(KeyCode.D)) {
			movement += localRight;
		}
		if (Input.GetKey(KeyCode.Space)) {
			movement += localUp;
		}
		if (Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.C)) {
			movement -= localUp;
		}

		//Normalise it and move the camera.
		movement.Normalize();
		movement *= movementSpeed * Time.deltaTime;
		cameraParent.transform.position += movement;
	}

	private Vector3 CalculateVectorFromCameraToTarget(Transform target) {
		Vector3 vector = target.position - transform.position;
		vector = vector.normalized;
		return vector;
	}
	#endregion

	#region Public Access Functions (Getters and Setters).
	public Vector3 GetLocalUpVector()
    {
		return CalculateVectorFromCameraToTarget(upPoint);
    }
    #endregion
}
