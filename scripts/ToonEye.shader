Shader "Unlit/ToonEye"
{
    Properties
    {
        _Depth("Depth"   , Range(0, 1)) = 0.5
        _Gradient("Gradient", Range(0, 100)) = 20

        [Header(Iris)]
        _IrisBoundaryColor("Iris Boundary Color" , Color) = (0, 0, 1, 1)
        _IrisBoundaryRadius("Iris Boundary Radius", Range(0, 1)) = 0.4
        _IrisInteriorColor("Iris Interior Color" , Color) = (0, 1, 0, 1)
        _IrisInteriorRadius("Iris Interior Radius", Range(0, 1)) = 0.38

        [Header(Pupil)]
        _PupilBoundaryColor("Pupil Boundary Color" , Color) = (0.13333, 0.13725, 0.13725, 1)
        _PupilBoundaryRadius("Pupil Boundary Radius", Range(0, 1)) = 0.2
        _PupilInteriorColor("Pupil Interior Color" , Color) = (0.53725, 0.55294, 0.54118, 1)
        _PupilInteriorRadius("Pupil Interior Radius", Range(0, 1)) = 0.19

        [Header(Sclera)]
        _ScleraColor("Sclera Color", Color) = (0.94118, 0.96471, 0.94118, 1)
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            
            #pragma fragment frag
            #pragma vertex vert

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct v2f
            {
                fixed4 illumination : COLOR0;
                float4 clipPosition   : SV_POSITION;
                float3 objectPosition : TEXCOORD0;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed4 diffuse = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz)) * _LightColor0;
                fixed3 ambient = ShadeSH9(half4(worldNormal, 1));
                o.illumination = half4(ambient, 0) + diffuse;
                o.clipPosition = UnityObjectToClipPos(v.vertex);
                o.objectPosition = v.vertex;
                return o;
            }

            float _Depth;
            float _Gradient;
            fixed4 _IrisBoundaryColor;
            float _IrisBoundaryRadius;
            fixed4 _IrisInteriorColor;
            float _IrisInteriorRadius;
            fixed4 _PupilBoundaryColor;
            float _PupilBoundaryRadius;
            fixed4 _PupilInteriorColor;
            float _PupilInteriorRadius;
            fixed4 _ScleraColor;

            fixed4 frag(v2f i) : SV_Target
            {
                float mask = distance(0, float3(i.objectPosition.xy, i.objectPosition.z - _Depth));
              
                float PupilBoundaryMask = saturate(_Gradient * (1 - saturate(mask / _PupilBoundaryRadius)));
                float PupilInteriorMask = saturate(_Gradient * (1 - saturate(mask / _PupilInteriorRadius)));

                fixed4 pupilBoundary = (PupilBoundaryMask - PupilInteriorMask) * _PupilBoundaryColor;
                fixed4 pupilInterior = PupilInteriorMask * lerp(_PupilInteriorColor, _PupilBoundaryColor, mask / _PupilInteriorRadius);

                float IrisBoundaryMask = saturate(_Gradient * (1 - saturate(mask / _IrisBoundaryRadius)));
                float IrisInteriorMask = saturate(_Gradient * (1 - saturate(mask / _IrisInteriorRadius)));
               
                fixed4 irisBoundary = (IrisBoundaryMask - IrisInteriorMask) * _IrisBoundaryColor;
                fixed4 irisInterior = (IrisInteriorMask - PupilBoundaryMask) * lerp(_IrisInteriorColor, _IrisBoundaryColor, mask / _IrisInteriorRadius);

                fixed4 scleraInterior = (1 - IrisBoundaryMask) * _ScleraColor;

                fixed4 finalColor = (pupilBoundary + pupilInterior + irisBoundary + irisInterior + scleraInterior) * i.illumination;

                return finalColor;
            }
            ENDCG
        }
    }
}