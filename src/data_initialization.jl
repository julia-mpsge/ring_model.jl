"""
    initialize_data(N::Int; random_seed = 1234)

Initializes the data for the model. The data returns of the following:

- `regions`: A vector of symbols representing the regions in the model.
- `goods`: A vector of symbols representing the goods in the model.
- `starting_land_share`: A NamedArray with the initial land share for each good.
- `weight`: A NamedArray with the weight of each good in the utility function.

## Arguments

- `N::Int`: The number of regions in the model.

## Keyword Arguments
- `random_seed::Int = 1234`: The random seed to use for the random number generator.

## Example

To create data for 3 regions:

```julia
(regions, goods, starting_land_share, weight) = initialize_data(3)
```
"""
function initialize_data(N::Int; random_seed = 1234)
    Random.seed!(random_seed)

    regions = Symbol.("r",lpad.(1:N,2,"0"))
    goods = [:corn, :beans, :wheat]

    starting_land_share = NamedArray(rand(length(goods)),goods)
    weight = NamedArray(rand(length(goods)),goods)

    return regions, goods, starting_land_share, weight
end