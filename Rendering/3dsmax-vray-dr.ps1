param (
    [int]start = 1,
    [int]end = 1,
    [string]outputName = "images\image.jpg",
    [int]width = 800,
    [int]height = 600,
    [string]sceneFile
)

$port = 20207
$vraydr_file = "vray_dr.cfg"
$pre_render_script = "enable-dr.ms"

$env:AZ_BATCH_HOST_LIST.Split(",") | ForEach {
    "$_ $port" | Out-File -Append $vraydr_file
}

# Create vray_dr.cfg with cluster hosts
@"
restart_slaves 0
list_in_scene 0
max_servers 0
use_local_machine 0
transfer_missing_assets 1
use_cached_assets 1
cache_limit_type 2
cache_limit 100.000000
"@ | Out-File -Append $vraydr_file
cp $vraydr_file "$env:LOCALAPPDATA\Autodesk\3dsMax\2018 - 64bit\ENU\en-US\plugcfg\vray_dr.cfg"

# Create preRender script to enable distributed rendering in the scene
@"
vr=renderers.current
vr.system_distributedRender=true
"@ | Out-File $pre_render_script

mkdir images

3dsmaxcmdio.exe -secure off -v:5 -rfw:0 -start:$start -end:$end -outputName:"$outputName" -w $width -h $height "$sceneFile"