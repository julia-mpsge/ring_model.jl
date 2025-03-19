

function initialize_data(N::Int; random_seed = 1234)
    Random.seed!(random_seed)

    regions = Symbol.("r",lpad.(1:N,2,"0"))
    goods = [:corn, :beans, :wheat]

    starting_land_share = NamedArray(rand(length(goods)),goods)
    weight = NamedArray(rand(length(goods)),goods)

    return regions, goods, starting_land_share, weight
end