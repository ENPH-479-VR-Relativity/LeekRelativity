using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimeDilation : MonoBehaviour
{
    public RelativityProperties rp;
    private Transform objectPos;

    public float LocalTime = 0f;
    public float PlayerTime = 0f;

    void Start()
    {
        rp = GetComponent<RelativityProperties>();
        objectPos = rp.objectPos;
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 xo = objectPos.position; // Position of object.
        Vector3 vo = new Vector3(0f, 0f, 0f); // Velocity of object.
        Vector3 xoRelP = xo - rp.xp; // Position of object relative to player.

        Vector3 voAngPlr = new Vector3(
                rp.wp.y * xoRelP.z - rp.wp.z * xoRelP.y,
                rp.wp.z * xoRelP.x - rp.wp.x * xoRelP.z,
                rp.wp.x * xoRelP.y - rp.wp.y * xoRelP.x
            ); // Angular component of linear object velocity due to rotation of player (in view of player).

        Vector3 voRelP = vo + voAngPlr - rp.vp; // Velocity of object relative to player (adds effect of player's ang. velocity). 

        float playerSpeed = Mathf.Sqrt(rp.vp.x * rp.vp.x + rp.vp.y + rp.vp.y + rp.vp.z + rp.vp.z); // Speed of the player.
        float objectSpeed = Mathf.Sqrt(vo.x * vo.x + vo.y + vo.y + vo.z * vo.z); // Speed of the object.

        float voRelPSpeed = Mathf.Sqrt(voRelP.x * voRelP.x + voRelP.y * voRelP.y + voRelP.z * voRelP.z); // Speed of the object relative to the player.
        float voRelPDist = Mathf.Sqrt(xoRelP.x * xoRelP.x + xoRelP.y * xoRelP.y + xoRelP.z * xoRelP.z); // Distance of the object relative to the player.

        float xoDotVoRelP = voRelP.x * xoRelP.x + voRelP.y * xoRelP.y + voRelP.z * xoRelP.z; // Dot product of object velocity and position, both rel. to player.
        float cosAngXoVoRelP = xoDotVoRelP / (voRelPSpeed * voRelPDist); // Cosine of the angle between the relative velocity of the object and the relative position of the object (both rel. to player).

        float beta = voRelPSpeed / rp.globalProperties.LightSpeed; // Beta as in Lorentz factor formula
        float gamma = 1 / Mathf.Sqrt(1 - Mathf.Min(beta * beta, 0.99999f)); // Lorentz factor

        LocalTime += gamma * Time.deltaTime;
        PlayerTime += Time.deltaTime;
        print("Player: " + PlayerTime + "; Object: " + LocalTime + "; Gamma: " + gamma + "; RelSpeed: " + voRelPSpeed);
    }
}
