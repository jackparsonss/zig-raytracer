# Zig Raytracer

### Usage

```
# PPM
zig build -Doptimize=ReleaseFast run -Dformat=ppm

# PNG
zig build -Doptimize=ReleaseFast run -Dformat=png
```

# Specify a Scene
```
zig build -Doptimize=ReleaseFast run -Dscene=base.xml
```

# Specify output file(file extension will be inferred from format)
```
zig build -Doptimize=ReleaseFast run -Doutput=traced
```

# All the above
```
zig build -Doptimize=ReleaseFast run -Dformat=png -Dscene=base.xml -Doutput=traced
```

### Scenes
By default the `base.xml` scene will run.
All scenes must include a camera such as 

```
<camera>
    <aspect_ratio>16.0/9.0</aspect_ratio>
    <image_width>400</image_width>
    <samples_per_pixel>10</samples_per_pixel>
    <max_depth>10</max_depth>
    <fov>20.0</fov>

    <lookfrom x="13" y="2" z="3" />
    <lookat x="0" y="0" z="0" />
    <vup x="0" y="1" z="0" />

    <defocus_angle>0.6</defocus_angle>
    <defocus_dist>10.0</defocus_dist>
</camera>
```

Scenes then require objects, you can specify as many objects as you want within the `<objects>` tag.
```
<objects>
    <sphere>
        <center x="0" y="-1000" z="0" />
        <radius>1000</radius>
        <material type="lambertian">
            <albedo r="0.5" g="0.5" b="0.5" />
        </material>
    </sphere>
</objects>
```
