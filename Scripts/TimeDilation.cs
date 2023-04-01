using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimeDilation : MonoBehaviour
{
    private Transform objectPos;
    private GlobalProperties globalProperties;

    public float LocalTime = 0f;
    public float PlayerTime = 0f;
    public float gamma = 1f;

    void Start()
    {
        objectPos = GetComponent<Transform>();
        globalProperties = FindObjectOfType<GlobalProperties>();
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 xo = objectPos.position; // Position of object.
        Vector3 vo = new Vector3(0f, 0f, 0f); // Velocity of object.
        Vector3 xoRelP = xo - globalProperties.Position; // Position of object relative to player.

        Vector3 voAngPlr = new Vector3(
                globalProperties.AngularVelocity.y * xoRelP.z - globalProperties.AngularVelocity.z * xoRelP.y,
                globalProperties.AngularVelocity.z * xoRelP.x - globalProperties.AngularVelocity.x * xoRelP.z,
                globalProperties.AngularVelocity.x * xoRelP.y - globalProperties.AngularVelocity.y * xoRelP.x
            ); // Angular component of linear object velocity due to rotation of player (in view of player).

        Vector3 voRelP = vo + voAngPlr - globalProperties.Velocity; // Velocity of object relative to player (adds effect of player's ang. velocity). 

        float playerSpeed = Mathf.Sqrt(
            globalProperties.Velocity.x * globalProperties.Velocity.x +
            globalProperties.Velocity.y + globalProperties.Velocity.y +
            globalProperties.Velocity.z + globalProperties.Velocity.z); // Speed of the player.
        float objectSpeed = Mathf.Sqrt(vo.x * vo.x + vo.y + vo.y + vo.z * vo.z); // Speed of the object.

        float voRelPSpeed = Mathf.Sqrt(voRelP.x * voRelP.x + voRelP.y * voRelP.y + voRelP.z * voRelP.z); // Speed of the object relative to the player.
        float voRelPDist = Mathf.Sqrt(xoRelP.x * xoRelP.x + xoRelP.y * xoRelP.y + xoRelP.z * xoRelP.z); // Distance of the object relative to the player.

        float xoDotVoRelP = voRelP.x * xoRelP.x + voRelP.y * xoRelP.y + voRelP.z * xoRelP.z; // Dot product of object velocity and position, both rel. to player.
        float cosAngXoVoRelP = xoDotVoRelP / (voRelPSpeed * voRelPDist); // Cosine of the angle between the relative velocity of the object and the relative position of the object (both rel. to player).

        float beta = voRelPSpeed * globalProperties.TimeScalar / globalProperties.LightSpeed; // Beta as in Lorentz factor formula
        
        gamma = 1 / Mathf.Sqrt(1 - Mathf.Min(beta * beta, 0.99999f)); // Lorentz factor

        LocalTime += gamma * Time.deltaTime;
        PlayerTime += Time.deltaTime;
        // print("Player: " + PlayerTime + "; Object: " + LocalTime + "; Gamma: " + gamma + "; RelSpeed: " + voRelPSpeed);
    }
}
