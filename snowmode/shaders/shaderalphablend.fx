texture Tex;
float4 DiffuseColor;

sampler2D InputTexture : register(s0);

sampler TextureSampler = sampler_state
{
    Texture   = (Tex);
};

float4 main(float2 TexCoords : TEXCOORD0) : COLOR
{
	float4 colorSnow = tex2D( TextureSampler, TexCoords );
	float4 colorDefault = tex2D( InputTexture, TexCoords );
	
    return ( colorSnow * colorDefault.a ) * DiffuseColor;
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
		Texture[0] = Tex;
    }
}

