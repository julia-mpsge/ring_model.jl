function ring_mpsge(
        regions, 
        goods, 
        starting_land_share, 
        weight;
        initial_labor_endowment = 5000
    )


    distance = NamedArray(get.(enumerate(regions),1,0), regions)
    area = NamedArray([pi*(r^2-(r-1)^2) for r∈distance], regions)

    M = MPSGEModel()

    @parameters(M, begin
        labor_endowment, initial_labor_endowment
        land_share[goods], 0
        land_tax[regions], 0
    end)


    for g∈goods
        set_value!(land_share[g], starting_land_share[g])
    end

    @sectors(M, begin
        transport[regions,goods]
        agriculture[regions,goods]
    end)

    @commodities(M, begin
        price[goods]
        region_good_price[regions, goods]
        land_price[regions]
        labor_price
    end)


    @consumers(M, begin
        workers
        landowners
    end)

    for r∈regions, g∈goods
        @production(M, transport[r,g], [s=0,t=0], begin
            @output(price[g], 1, t)
            @input(labor_price, distance[r]*weight[g], s)
            @input(region_good_price[r,g], 1, s)
        end)
    end


    for r∈regions, g∈goods
        @production(M, agriculture[r,g], [s=1, t=0], begin
            @output(region_good_price[r,g], 1, t)
            @input(land_price[r], land_share[g], s)#, taxes = [Tax(workers, land_tax[r])])
            @input(labor_price, 1-land_share[g], s)
        end)
    end

    @demand(M, workers, begin
            [@final_demand(price[g], 1) for g∈goods]...
            @endowment(labor_price, labor_endowment)
    end)

    @demand(M, landowners, begin
            [@final_demand(price[g], 1) for g∈goods]...
            [@endowment(land_price[r], area[r]) for r∈regions]...
    end)

    
    set_lower_bound.(land_price, 1e-6)

    return M
end

function ring_mcp(        
        regions, 
        goods, 
        starting_land_share, 
        weight;
        initial_labor_endowment = 5000
    )


    distance = NamedArray(get.(enumerate(regions),1,0), regions)
    area = NamedArray([pi*(r^2-(r-1)^2) for r∈distance], regions)
    
    M = Model(PATHSolver.Optimizer)

    @variables(M, begin
        # Parameters
        labor_endowment in JuMP.Parameter(initial_labor_endowment)
        land_share[g=goods] in JuMP.Parameter(starting_land_share[g])

        # Sectors
        transport[regions,goods] >= 0, (start = 1)
        agriculture[regions,goods] >= 0, (start = 1)

        # Commodities
        price[goods] >= 0, (start = 1)
        region_good_price[regions, goods] >= 0, (start = 1)
        land_price[regions] >= 0, (start = 1)
        labor_price >= 0, (start = 1)

        # Consumers
        workers >= 0, (start = 1)
        landowners >= 0, (start = 1)
    end)



    # Zero Profit Conditions, one for each sector
    @constraint(M, transport_zero_profit[r=regions, g=goods], 
        labor_price*distance[r]*weight[g] + region_good_price[r,g] - price[g] ⟂ transport[r,g]
    )

    @constraint(M, agriculture_zero_profit[r=regions, g=goods], 
        land_price[r]^(land_share[g])*labor_price^(1-land_share[g]) - region_good_price[r,g] ⟂ agriculture[r,g]
    )

    # Market Clearnacnce Conditions, one for each commodity
    @constraint(M, price_mc[g=goods], 
        sum(transport[r,g] for r∈regions) - (1/3*workers/price[g] + 1/3*landowners/price[g]) ⟂ price[g]
    )

    @constraint(M, region_good_price_mc[r=regions, g=goods], 
        agriculture[r,g] - transport[r,g] ⟂ region_good_price[r,g]
    )

    @constraint(M, land_price_mc[r=regions], 
        -sum(agriculture[r,g]*(labor_price^(1-land_share[g])*land_share[g]*land_price[r]^(land_share[g]-1)) for g∈goods) + area[r] ⟂ land_price[r]
    )

    @constraint(M, labor_price_mc,
        -sum(transport[r,g]*distance[r]*weight[g] for r∈regions, g∈goods) + 
        -sum(agriculture[r,g]*(land_price[r]^(land_share[g])*(1-land_share[g])*labor_price^(-land_share[g])) for r∈regions, g∈goods) +
        labor_endowment ⟂ labor_price
    )

    # Income Balance Conditions, one for each consumer
    @constraint(M, workers_ib, 
        workers - labor_price*labor_endowment ⟂ workers
    )

    @constraint(M, landowners_ib, 
        landowners - sum(land_price[r]*area[r] for r∈regions) ⟂ landowners
    )

    set_lower_bound.(land_price, 1e-6)

    return M

end