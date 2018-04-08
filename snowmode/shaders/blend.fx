texture Tex2;
texture BlendTex;

float4 DiffuseColor;

sampler2D InputTexture : register(s0);

sampler Texture2Sampler = sampler_state
{
    Texture   = (Tex2);
};

sampler BlendTextureSampler = sampler_state
{
    Texture   = (BlendTex);
};

float4 main(float2 TexCoords : TEXCOORD0) : COLOR
{	
	float4 TexColor1 = tex2D( Texture2Sampler, TexCoords );
    float4 TexColor2 = tex2D( InputTexture, TexCoords );
    float4 BlendMap  = tex2D( BlendTextureSampler, TexCoords / 6 );
    
	//TexColor1 = TexColor1 * DiffuseColor;
	//TexColor2 = TexColor2 * DiffuseColor;
	
    return (TexColor1 * BlendMap.g) + (TexColor2 * BlendMap.b) * DiffuseColor;
}

technique tec0
{
    pass P0
    {
		PixelShader = compile ps_2_0 main();
    }
}

technique fallback
{
    pass P0
    {
		Texture[0] = Tex2;
    }
}

