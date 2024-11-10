#pragma header

void main(void)
{
    vec2 uv = openfl_TextureCoordv.xy;
    uv.x = abs(uv.x-1.0);

    gl_FragColor = texture2D(bitmap, uv);
}
