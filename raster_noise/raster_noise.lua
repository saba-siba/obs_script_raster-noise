obs = obslua
bit = require("bit")
math.randomseed(os.time())

source_def = {}
source_def.id = 'filter-raster_noise'
source_def.type = obs.OBS_SOURCE_TYPE_FILTER
source_def.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO)
noise_time=0
noise=false
interval=1

function set_render_size(filter)
    target = obs.obs_filter_get_target(filter.context)

    local width, height
    if target == nil then
        width = 0
        height = 0
    else
        width = obs.obs_source_get_base_width(target)
        height = obs.obs_source_get_base_height(target)
    end

    filter.width = width
    filter.height = height
    width = width == 0 and 1 or width
    height = height == 0 and 1 or height
    filter.pix_size.x = 1.0 / width
    filter.pix_size.y = 1.0 / height
	--print(filter.pix_size.x)
	--print("aa")
end


function set_noise(noise)
if noise==true then 
	return false
end
return true
end

source_def.get_name = function()
    return "raster_noise"
end

source_def.create = function(settings, source)
    local effect_path = script_path() .. 'raster_noise.effect'

	--パラメーターの初期化
	--filterに代入する前の値
	--filiter.paramsに代入した値をエフェクトに渡す
    filter = {}
    filter.params = {}
    filter.context = source
    filter.pix_size = obs.vec2()
	filter.noise_max=0
	filter.noise_min=0
	filter.noise_rate=0.2
	filter.timer=0
	filter.freq=200
	filter.display_time=60

    set_render_size(filter)

    obs.obs_enter_graphics()
    filter.effect = obs.gs_effect_create_from_file(effect_path, nil)
    if filter.effect ~= nil then
        filter.params.pix_size = obs.gs_effect_get_param_by_name(filter.effect, 'pix_size')
		filter.params.noise_distance = obs.gs_effect_get_param_by_name(filter.effect, 'noise_distance')
		filter.params.noise_rate=obs.gs_effect_get_param_by_name(filter.effect, 'noise_rate')
		filter.params.timer=obs.gs_effect_get_param_by_name(filter.effect, 'timer')
		filter.params.freq=obs.gs_effect_get_param_by_name(filter.effect, 'freq')
		filter.params.display_time=obs.gs_effect_get_param_by_name(filter.effect, 'display_time')

    end
    obs.obs_leave_graphics()
    
    if filter.effect == nil then
        source_def.destroy(filter)
        return nil
    end

    source_def.update(filter, settings)
    return filter
end

source_def.destroy = function(filter)
    if filter.effect ~= nil then
        obs.obs_enter_graphics()
        obs.gs_effect_destroy(filter.effect)
        obs.obs_leave_graphics()
    end
end

source_def.get_width = function(filter)
    return filter.width
end

source_def.get_height = function(filter)
    return filter.height
end

source_def.update = function(filter, settings)
    filter.noise_max=obs.obs_data_get_int(settings, 'noise_max')
	filter.noise_min=obs.obs_data_get_int(settings, 'noise_min')
	filter.noise_rate=obs.obs_data_get_double(settings, 'noise_rate')
	interval=obs.obs_data_get_int(settings, 'interval')
	filter.freq=obs.obs_data_get_int(settings, 'freq')
	filter.display_time=obs.obs_data_get_int(settings, 'display_time')

end

source_def.video_render = function(filter, effect)
    obs.obs_source_process_filter_begin(filter.context, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)
	obs.gs_effect_set_vec2(filter.params.pix_size, filter.pix_size)
	obs.gs_effect_set_int(filter.params.timer,filter.timer)
	obs.gs_effect_set_float(filter.params.noise_rate,filter.noise_rate)
	obs.gs_effect_set_int(filter.params.freq,filter.freq)
	obs.gs_effect_set_int(filter.params.display_time,filter.display_time)

	if noise==true then
		obs.gs_effect_set_int(filter.params.noise_distance,filter.noise_max)
	else
		obs.gs_effect_set_int(filter.params.noise_distance,filter.noise_min)
	end

	obs.obs_source_process_filter_end(filter.context, filter.effect, filter.width, filter.height)


	if filter.timer==noise_time then
		if noise==true then
			noise_time=noise_time+interval+math.random(interval+30)--tekitou
		end
		noise_time=noise_time+math.random(3,16)
		noise=set_noise(noise)
		--print(noise_time)
		if noise_time>36000 then
			noise_time=noise_time-36000
		end
	end
	
	filter.timer=filter.timer+1
	if filter.timer > 36000 then
		filter.timer=0
	end

	
end

source_def.get_properties = function(settings)
	props = obs.obs_properties_create()
    obs.obs_properties_add_int_slider(props,'noise_max','deflection width max', 0, 300, 1)
	obs.obs_properties_add_int_slider(props,'noise_min','deflection width ordinary', 0, 300, 1)
	obs.obs_properties_add_int_slider(props,'interval','interval about min noise max noise', 1, 600, 1)
	obs.obs_properties_add_float_slider(props,'noise_rate','rate of noise', 0.01, 1, 0.01)
	obs.obs_properties_add_int_slider(props,'freq','frequency', 1, 400, 1)
	obs.obs_properties_add_int_slider(props,'display_time','display time interval', 1, 30, 1)
	return props
end

source_def.get_defaults = function(settings)
   obs.obs_data_set_default_int(settings,'noise_max', 80)
   obs.obs_data_set_default_int(settings,'noise_min', 20)
   obs.obs_data_set_default_int(settings,'interval', 200)
   obs.obs_data_set_default_double(settings,'noise_rate', 0.2)
   obs.obs_data_set_default_int(settings,'freq', 200)
   obs.obs_data_set_default_int(settings,'display_time', 1)
end

source_def.video_tick = function(filter, seconds)
    set_render_size(filter)
end

obs.obs_register_source(source_def)
