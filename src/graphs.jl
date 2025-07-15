
"""
    ring_data(number_regions::Int; labor_endowment_range = 10_000:10_000:1_000_000)

Compute the land value data for the ring model with a specified number of regions 
and a range of labor endowments.

## Arguments

- `number_regions::Int`: The number of regions in the model.
- `labor_endowment_range::UnitRange{Int}`: The range of labor endowments to compute land values for. Default is `10_000:10_000:1_000_000`.

## Returns

A land value DataFrame generated using [`build_land_value!`](@ref) for each labor endowment in the specified range.

"""
function ring_data(number_regions::Int; labor_endowment_range = 10_000:10_000:1_000_000)

    (regions, goods, starting_land_share, weight) = initialize_data(number_regions)

    R = ring_mpsge(regions, goods, starting_land_share, weight)
    fix(R[:labor_price],1)
    set_silent(R)

    land_value = DataFrame()
    for labor_endowment in labor_endowment_range
        set_value!(R[:labor_endowment], labor_endowment)
        solve!(R)
        
        land_value = build_land_value!(land_value, R, labor_endowment; regions = regions)
    end

    return land_value
end

"""
    build_land_value!(df::DataFrame, M::MPSGEModel, labor_endowment::Int; regions = regions)

Builds and appends land value data to the provided DataFrame.

## Returns

A DataFrame with columns given by `regions`, `land_value`, `distance`, `labor_endowment`, and `normalized_land_value`.
"""
function build_land_value!(df::DataFrame, M::MPSGEModel, labor_endowment::Int; regions = regions)
    land_value = Vector(value.(M[:land_price]))
    land = DataFrame(
        region = regions,
        land_value = land_value,
        distance = get.(enumerate(regions),1,0),
        labor_endowment = labor_endowment,
        normalized_land_value = land_value ./ maximum(land_value), 
    )

    return vcat(df, land)
end


function fill_color(land_value::Number)
    lv = 1-land_value
    return "rgb($(255*lv),$(255*lv),$(255*lv))"
end


function land_value_plot(land_value::DataFrame, labor_endowment::Int)
    X = subset(land_value, :labor_endowment => ByRow(==(labor_endowment))) |> 
        x -> sort(x, :distance, rev=true) |>
        x -> transform(x, 
            :land_value => (y -> y ./ maximum(y)) => :normalized_land_value,
        ) 
    return [
        attr(
            type = "circle", 
            xref = "x", yref = "y",
            fillcolor = fill_color(row[:normalized_land_value]),
            x0 = -row[:distance], y0 = -row[:distance], 
            x1 = row[:distance], y1 = row[:distance],
            label = attr(
                text = round(row[:normalized_land_value], digits = 4),
                textposition = "top center",
                font = attr(
                    color = "blue",
                    size = 30,
                )
            )
    ) for row in eachrow(X)]
end

"""
    ring_animation(land_value::DataFrame; file_name = "example.html")

Creates an animated plot of the ring model land value data. Outputs an HTML 
file with the animation.

## Arguments

- `land_value::DataFrame`: The DataFrame containing land value data.
- `file_name::String`: The name of the file to save the animation. Default is "example.html".
"""
function ring_animation(land_value::DataFrame; file_name = "example.html")

    labor_endowments = unique(land_value[!,:labor_endowment]) |> collect


    ## Animation
    begin
        frames = land_value |>
            X -> Vector{PlotlyFrame}([
                frame(
                    layout = attr(
                        title_text = "Labor Endowment: $(labor_endowment)",
                        shapes = land_value_plot(X, labor_endowment)
                        ),
                    name = labor_endowment,
                ) for labor_endowment in labor_endowments]
            )

        updatemenus = [
            attr(
                type="buttons", 
                active=0,
                y=1,  #(x,y) button position 
                x=1.1,
                buttons=[
                    attr(
                        label="Play",
                        method="animate",
                        args=[
                            nothing,
                            attr(frame=attr(duration=50, 
                                            redraw=true),
                                transition=attr(duration=0),
                                fromcurrent=true,
                                mode="immediate"
                                )
                            ]
                        )
                    ]
                )
            ];

        sliders = [
            attr(
                active=0, 
                minorticklen=0,    
                steps=[
                    attr(
                        label= labor_endowment,
                        method="animate",
                        args=[
                            [labor_endowment], # match the frame[:name]
                            attr(mode="immediate",
                                transition=attr(duration=0),
                                frame=attr(
                                    duration=50000, 
                                    redraw=true)
                            )
                        ]) for labor_endowment in labor_endowments
                    ]
                )
            ];  

        layout = land_value |>
            X -> Layout(
                xaxis_range=[-maximum(X[!,:distance]), maximum(X[!,:distance])],
                xaxis_zeroline=false,
                yaxis_range=[-maximum(X[!,:distance]), maximum(X[!,:distance])],
                width=800,
                height=800,
                axis=([], false),
                grid = false,
                updatemenus = updatemenus,
                sliders = sliders,
                title = attr(
                    title= "Ring Model Land Value",
                )
            )


        trace = scatter(
            x=[0, 0],
            y=[0, 0],
            mode="markers",
        )

        p1 = plot(trace, layout, frames)

        open(file_name, "w") do io
            PlotlyBase.to_html(io, p1.plot)
        end
    end
end

"""
    ring_plot(land_value::DataFrame; y = :normalized_land_value)

Creates a plot of the ring model land value data.

## Arguments

- `land_value::DataFrame`: The DataFrame containing land value data.
- `y::Symbol`: The column to plot on the y-axis. Default is `:normalized_land_value`.

## Returns

A list of traces to plot. 

## Example

```julia
df = ring_data(5)

plot(create_ring_plot(df))
"""
function ring_plot(land_value::DataFrame; y = :normalized_land_value)
    df = groupby(land_value, :region)

    traces = [
        scatter(
            DataFrame(X),
            x = :labor_endowment,
            y = y,
            mode = "lines",
            name = name[:region],
        ) for (name, X) in pairs(df)]

    return traces

end

"""
    ring_plot_button(df::DataFrame)

Creates a plot with buttons to toggle between normalized land value and land value.

## Arguments

- `df::DataFrame`: The DataFrame containing land value data.

## Returns

A PlotlyJS plot with buttons to toggle between normalized land value and land value.
"""
function ring_plot_button(df::DataFrame)
    traces = [ring_plot(df); ring_plot(df; y = :land_value)]
    N = length(traces)/2

    group1 = [[true for r in 1:N]; [false for r in 1:N]]
    group2 = [[false for r in 1:N]; [true for r in 1:N]]

    P = plot(
        traces,
        Layout(
            updatemenus = [
                attr(
                    type="buttons", 
                    active=0,
                    y=1,  
                    buttons=[
                        attr(
                            label = "Normalized Land Value",
                            method = "update",
                            args = [
                                attr(visible = group1)
                            ]
                        ),
                        attr(
                            label = "Land Value",
                            method = "update",
                            args = [
                                attr(visible = group2)
                            ]
                        ),
                    ]
                )
            ]
        )
    )

    return P
end