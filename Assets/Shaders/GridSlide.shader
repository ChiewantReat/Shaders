Shader "Unlit/GridSlide"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}            // main image texture
        _GridX ("Grid Columns", Float) = 8               // number of columns in the grid
        _GridY ("Grid Rows", Float) = 8                  // number of rows in the grid
        _SlideAmount ("Slide Amount", Range(0,0.5)) = 0.18 // how far each tile shifts
        _CycleLength ("Cycle Length", Float) = 4.0       // total time for the full 4-phase animation
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }                   // render as a normal opaque object
        LOD 100                                          // simple shader detail level

        Pass
        {
            CGPROGRAM
            #pragma vertex vert                          // vertex shader entry point
            #pragma fragment frag                        // fragment shader entry point
            #include "UnityCG.cginc"                     // Unity shader helpers

            sampler2D _MainTex;                          // main texture sampler
            float4 _MainTex_ST;                          // texture tiling/offset
            float _GridX;                                // number of columns
            float _GridY;                                // number of rows
            float _SlideAmount;                          // how far tiles move
            float _CycleLength;                          // total time for all four phases

            struct appdata
            {
                float4 vertex : POSITION;                // mesh vertex position
                float2 uv : TEXCOORD0;                   // mesh UV coordinates
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;                   // UV passed to the fragment shader
                float4 vertex : SV_POSITION;             // clip-space position
            };

            v2f vert (appdata v)
            {
                v2f o;                                   // create output struct
                o.vertex = UnityObjectToClipPos(v.vertex); // convert vertex to clip space
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);    // apply texture tiling/offset
                return o;                                // send data onward
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;                        // starting UV coordinates

                float2 gridCount = float2(_GridX, _GridY); // total grid size in cells
                float2 cellUV = uv * gridCount;          // convert UV into grid space
                float2 cellID = floor(cellUV);           // determine which cell this pixel belongs to
                float2 localUV = frac(cellUV);           // determine the pixel's local position inside the cell

                float t = fmod(_Time.y, _CycleLength);   // wrap elapsed time so the animation repeats
                float phaseLen = _CycleLength / 4.0;     // each of the four phases gets equal time
                float phase = floor(t / phaseLen);       // determine the current phase number
                float phaseT = frac(t / phaseLen);       // progress from 0 to 1 within the current phase

                float2 offset = float2(0,0);             // movement offset applied to this tile

                if (phase == 0)
                {
                    offset.x = lerp(-_SlideAmount, 0.0, phaseT); // returns tiles horizontally
                }
                else if (phase == 1)
                {
                    offset.y = lerp(_SlideAmount, 0.0, phaseT);  // returns them vertically
                }
                else if (phase == 2)
                {
                    offset.x = lerp(_SlideAmount, 0.0, phaseT);  // returns them from the opposite horizontal side
                }
                else
                {
                    offset.y = lerp(-_SlideAmount, 0.0, phaseT); // returns them from the opposite vertical side
                }

                float parity = fmod(cellID.x + cellID.y, 2.0);   // checkerboard-ish alternation between neighboring cells

                if (phase == 0)
                    offset.x *= (parity < 0.5 ? 1.0 : -1.0);     // alternate left/right movement by cell
                else if (phase == 1)
                    offset.y *= (parity < 0.5 ? 1.0 : -1.0);     // alternate up/down movement by cell
                else if (phase == 2)
                    offset.x *= (parity < 0.5 ? -1.0 : 1.0);     // reverse horizontal directions for later phase
                else
                    offset.y *= (parity < 0.5 ? -1.0 : 1.0);     // reverse vertical directions for final phase

                float2 finalUV = (cellID + localUV) / gridCount; // rebuild the original UV from cell ID and local position
                finalUV += offset;                               // shift the tile's sampled area for the sliding effect

                fixed4 col = tex2D(_MainTex, finalUV);           // sample the imperial legion soldier image from the shifted UV
                return col;                                      // output the final color
            }
            ENDCG
        }
    }
}