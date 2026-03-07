shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 0.5;

float bayer4(vec2 p){
    int x = int(mod(p.x, 4.0));
    int y = int(mod(p.y, 4.0));

    int index = x + y * 4;

    float[16] matrix = float[16](
        0.0, 8.0, 2.0, 10.0,
        12.0,4.0,14.0,6.0,
        3.0,11.0,1.0,9.0,
        15.0,7.0,13.0,5.0
    );

    return matrix[index] / 16.0;
}

void fragment(){
    vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);

    float threshold = bayer4(FRAGCOORD.xy);

    if(strength < threshold){
        discard;
    }

    COLOR = screen;
}