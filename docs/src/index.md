# Ring Model

In this write up we am going to assume you have a basic understanding on how to use Julia. If you are not familiar with Julia, we recommend you to go through the [official documentation](https://docs.julialang.org/en/v1/).

In this tutorial we will guide you through a simple algebraic CGE model using JuMP and the corresponding MPSGE model. The goal is demonstrate the basic concepts of MPSGE modeling, compare it to the algebraic model and show the simplicity/power of the MPSGE syntax. 

## Scenario Introduction

Consider a point city, a city with radius 0, at the center of concentric circular files. Denote each ring as $r_i$ so that $r_1$ is adjancent to the city and $r_N$ is the outermost ring. Assume ring $r_i$ has radius $i$ so that area of ring $r_i$ is given by 
```math
A(r_i) = \pi\left(i^2 - (i-1)^2\right)
```

Crops are grown in the fields and shipped to the city. For simplicity, assume three crops: corn, wheat and beans. Each crop has a land value share, or the share of land value due to crops rather than labor. These land value shares will be random between 0 and 1. Additionally, each crop has an associated  weight, also random between 0 and 1, that affects its transportation cost. The transportation cost of crop $g$ from region $r$ to the city center is given by the radius of region $r$ times the weight of crop $g$.

There are two representative agents in the city, workers and landowners. Both agents live in the central point city and consume 1 unit of each crop. Landowners endow each region with a value equal to the area of the region.Workers endow $L$ units of labor, where $L$ is a model parameter.  

We should make note that, as written, this model will be _unbalanced_. This means the benchmark data will not be consistent with the model equations. In general, this makes modeling significantly more difficult as you are unable to verify your the equations of the model are correct and must rely on your intuition to validate the model structure. MPSGE makes this easier as you can easily verify the model structure without being concerned about equations.

## Understanding the Model Structure

When you being a problem it is important to identify the _sectors_ (markets), _commodities_ (prices), and _consumers_. The italicized terms are keywords in MPSGE. Let's start with the sectors, or markets, in the model. To identify the sectors ask "What is being bought and sold and where?". In this model there are are a large number of markets, but really there are only two distinct sectors: transportation and agriculture. We will discuss each sector in turn.

All consumers live in the city and consume crops. This means there must be a market transporting each good from each region to the city. This is the transportation sector. The transportation sector is indexed on both regions and crops, meaning there are $N \cdot G$ markets in the transportation sector. Each market will buy crops in region $r$ and use labor to transport the crops to the city where they will be sold and city prices.

The agriculture sector is responsible for growing crops in the regions. This sector is indexed on regions and crops, again there are $N \cdot G$ markets in the agriculture sector. Each farm needs to buy labor and land to grow crops and will sell crops at the local price. 

In our detailing of the sectors, we have identified a number of commodities, or prices: 
1. The price of goods in the city
2. The price of labor
3. The price of land
4. The price of goods in each region
That turns out to be all the prices. The sectors and commodities are linked, in general you shouldn't have prices that are not present in the sectors, this is possible but we'll discuss the rules later.

Finally, the problem statement identifies two consumers: workers and landowners. These are not indexed, think of the workers as a pool of labor that is endowed to the markets. This is how we analyze consumers, what do they endow (give) to the market and what do they demand (consume). Both workers and landowners demand goods. Workers endow the market with labor and landowners endow the market with land.

## Algebraic Model

Before we dive into actual code, lets layout the equations of the model. There are three types of constraints:
1. Zero Profit
2. Market Clearance
3. Income Balance

Let's start with zero profit. For each sector we must have 
```math
-\text{Profit} = \text{Cost} - \text{Revenue} = 0.
```
Let $r$ be a region and $g$ be a good. Consider the `transportation[r,g]` sector, Figure (1) shows the inputs (costs) and output (revenue) of the sector. The cost function is given by a CES function with elasticity of substitution of 0,
```math
    \text{labor\_price}\cdot\text{distance}[r]\cdot\text{weight}[g] + \text{region\_good\_price}[r,g]\cdot 1.
```
It's a useful exercise to compare the cost function to the inputs of the transportation sector. The revenue is similarly given by 
```math
    \text{price}[g]\cdot 1.
```
Combining these we have the zero profit condition for the transportation sector,
```math
\begin{align*}
   \text{labor\_price}\cdot\text{distance}[r]\cdot\text{weight}[g] + \text{region\_good\_price}[r,g] - \\ \text{price}[g] \perp  \text{transport}[r,g]
   \end{align*}
```
Note that this is a complementarity constraint. 

The agriculture sector is similar, but with a CES cost function with elasticity of substitution of 1, or Cobb-Douglass. The zero profit condition for the agriculture sector is 
```math
    \text{land\_price}[r]^{\text{land\_share}[g]}\cdot\text{labor\_price}^{1-\text{land\_share}[g]} - \text{region\_good\_price}[r,g] ⟂ \text{agriculture}[r,g]
```

This brings us to market clearance. Let $\Pi_s$ be the profit function for sector $s$, $a_s$ be the activity level of sector $s$, $H$ be the consumers, and
$I_h$ be the income of consumer $h$. Then for each commodity $p$ the market clearance condition is given by
then for each commodity $p$ the market clearance condition is given by
```math
    \sum_{s\in S} a_s\cdot\frac{\partial \Pi_s}{\partial p} - \sum_{h∈H} \frac{\partial I_h}{\partial p}= 0.
```
THIS NEEDS SOME CLEAN UP

