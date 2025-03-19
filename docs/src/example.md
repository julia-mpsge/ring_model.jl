# Basic Example

In this example we will set up two models, one in MPSGE and one in MCP. The two models are identical and give the same solutions. 

```julia
using ring_model

using MPSGE, JuMP

(regions, goods, starting_land_share, weight) = initialize_data(40)

M = ring_mcp(regions, goods, starting_land_share, weight)

fix(M[:labor_price], 1; force=true)

optimize!(M)

R = ring_mpsge(regions, goods, starting_land_share, weight)
fix(R[:labor_price],1)

solve!(R)

value.(R[:price])

value.(M[:price])
```
