//-----------------------------------------------------------------------
//-- Settings
//-----------------------------------------------------------------------
float4 L_hemi_color = float4(0.50f,	0.50f,	0.50f, 1.0f);
float3 L_sun_color = float3(1.000f,  0.6f,  0.3f);
float3 L_sun_dir_w = float3(-0.3395f, -0.4226f, -0.8403f);
float3 L_ambient = float3(0.071f,   0.07f,  	0.079f);

texture Tex0;   //-- Replacement texture
texture Tex1;   //-- Replacement texture

bool useNM;
 
//---------------------------------------------------------------------
// Include some common stuff
//---------------------------------------------------------------------
#include "mta-helper.fx"
 
 
//-----------------------------------------------------------------------
//-- Sampler for the new texture
//-----------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (Tex0);
};
sampler Sampler1 = sampler_state
{
    Texture = (Tex1);
};
 
 
//-----------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//-----------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    float3 Normal : NORMAL0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
//-----------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//-----------------------------------------------------------------------
struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float4 Light : TEXCOORD1;
};
 
 
//--------------------------------------------------------------------------------------------
//-- VertexShaderFunction
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//--------------------------------------------------------------------------------------------
#define L_SUN_HACK 	(.7)
#define PI (3.14159265f)

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
 
    float3 WorldPos = MTACalcWorldPosition( VS.Position );
 
	float3 meshCenter = WorldPos - VS.Normal;
	float3 normal = meshCenter - gCameraPosition;
	normal.z = 0;
	normal = normalize ( normal );
	float3 up = float3(0, 0, 1);
	float3 right = normalize(cross(normal, up));

    float rot = atan2(-normal.x, -normal.y) + PI;
    float factor = floor(8 * (rot / (PI*2)));
 
 
     //-- Calculate screen pos of vertex
	float3 ourVertex;
	ourVertex.x = (VS.Position.x - VS.Normal.x) + right.x * VS.Normal.x;
	ourVertex.y = (VS.Position.y - VS.Normal.y) + right.y * VS.Normal.x;
	ourVertex.z = VS.Position.z;
    PS.Position = mul(float4(ourVertex, 1), gWorldViewProjection);
 
    //-- Pass through tex coord
    PS.TexCoord = VS.TexCoord;
 
    //-- Calculate GTA lighting for buildings
    PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );
    //--
    //-- NOTE: The above line is for GTA buildings.
    //-- If you are replacing a vehicle texture, do this instead:
    //--
    //--      // Calculate GTA lighting for vehicles
    //--      float3 WorldNormal = MTACalcWorldNormal( VS.Normal );
    //--      PS.Diffuse = MTACalcGTAVehicleDiffuse( WorldNormal, VS.Diffuse );
    
    float 	sun_c 	= 1 + L_SUN_HACK * dot(normal, L_sun_dir_w);		// [1+-delta], normal already inverted
    
    float3	l_hemi 	= L_hemi_color*0.3f;
	float3 	l_sun 	= L_sun_color*0.3f* sun_c;
	float3	light	= L_ambient + l_sun + l_hemi;
    
    PS.Light = float4(light, factor);
 
    return PS;
}
 
 
//--------------------------------------------------------------------------------------------
//-- PixelShaderFunction
//--  1. Read from PS structure
//--  2. Process
//--  3. Return pixel color
//--------------------------------------------------------------------------------------------
float4 PixelShaderFunction(PSInput PS) : COLOR0
{
    //-- Get texture pixel
    float4 texel = tex2D(Sampler0, PS.TexCoord + float2(PS.Light.w * (1.0f/32.0f), 0));
    float4 texel2 = tex2D(Sampler1, PS.TexCoord);
    
    float3 base = texel.rgb * PS.Light.rgb;
 
    //-- Apply diffuse lighting
    float3 finalColor = base * 2;
    if (useNM)
        finalColor *= (0.5+0.5*texel2.w);
 
    return float4(finalColor, texel.a * PS.Diffuse.a);
}
 
 
//--------------------------------------------------------------------------------------------
//-- Techniques
//--------------------------------------------------------------------------------------------
technique tec
{
    pass P0
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}
 
//-- Fallback
technique fallback
{
    pass P0
    {
        //-- Replace texture
        Texture[0] = Tex0;
 
        //-- Leave the rest of the states to the default settings
    }
}