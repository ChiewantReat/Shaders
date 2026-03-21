Shader "Custom/SnowAndRoll"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}          // main image texture used by the shader
        _ScrollSpeed ("Scroll Speed", Float) = 0.2     // how fast the image rolls sideways
        _SnowAmount ("Snow Amount", Range(0,1)) = 0.25 // how visible the snow is
        _SnowScale ("Snow Scale", Float) = 80.0        // how dense the snow pattern is
        _SnowSpeed ("Snow Speed", Float) = 1.5         // how fast the snow animates
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }                 // render as a normal opaque surface
        LOD 100                                        // simple shader detail level

        Pass
        {
            CGPROGRAM
            #pragma vertex vert                        // tells Unity which function is the vertex shader
            #pragma fragment frag                      // tells Unity which function is the fragment shader
            #include "UnityCG.cginc"                   // includes Unity helper code and macros

            sampler2D _MainTex;                        // lets us sample the main texture
            float4 _MainTex_ST;                        // stores tiling and offset values for the texture
            float _ScrollSpeed;                        // material-controlled scroll speed
            float _SnowAmount;                         // material-controlled snow intensity
            float _SnowScale;                          // material-controlled snow density
            float _SnowSpeed;                          // material-controlled snow movement speed

            struct appdata
            {
                float4 vertex : POSITION;              // incoming vertex position from the mesh
                float2 uv : TEXCOORD0;                 // incoming texture coordinates from the mesh
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;                 // UV passed from vertex shader to fragment shader
                float4 vertex : SV_POSITION;           // clip-space vertex position for rendering
            };

            v2f vert (appdata v)
            {
                v2f o;                                 // create output structure
                o.vertex = UnityObjectToClipPos(v.vertex); // convert object-space vertex to clip space
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);  // apply texture tiling and offset to the UV
                return o;                              // send the data to the fragment shader
            }

            float hash(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));  // scramble the coordinates into repeating random-looking values
                p += dot(p, p + 45.32);                // mix x and y together more to vary the pattern
                return frac(p.x * p.y);                // return a pseudorandom value from 0 to 1
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;                      // start from the interpolated UV coming from the mesh
                uv.x += _Time.y * _ScrollSpeed;        // move the image sideways over time using Unity's built-in _Time value

                fixed4 col = tex2D(_MainTex, uv);      // sample the rolled version of the texture

                float2 snowUV = i.uv;                  // use the original UVs for the snow layer
                snowUV.y += _Time.y * _SnowSpeed;      // animate the snow pattern over time
                snowUV *= _SnowScale;                  // scale the UV so many snow cells appear across the image

                float n = hash(floor(snowUV));         // generate one random value per snow cell
                n = step(0.90, n);                     // only keep the brightest random cells so the snow is sparse

                float flicker = hash(floor(snowUV + _Time.y * 10.0)); // add a time-varying flicker to the snow
                n *= lerp(0.6, 1.0, flicker);          // vary the brightness a little so the snow looks more alive

                col.rgb = lerp(col.rgb, 1.0.xxx, n * _SnowAmount); // blend snow toward white so it stays visible on light and dark areas
                return col;                            // output the final pixel color
            }
            ENDCG
        }
    }
}