#pragma header

void main(void)
{
    vec2 uv = openfl_TextureCoordv.xy;
    vec4 tex = texture2D(bitmap, uv);
    tex.r = 1.0-tex.r;
    tex.g = 1.0-tex.g;
    tex.b = 1.0-tex.b;

    gl_FragColor = vec4(tex.r, tex.g, tex.b, tex.a);
}
