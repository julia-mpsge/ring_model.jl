$title	Modeling Exercise: Von Thunens Land Use Model

*	Labor supply and commodity demand takes place at the center.

*	Land is organized in rings around the center.

*	Agricultural production requrires labor and land.

*	Transportation cost (labor input) depends on location and 
*	commodity weight.

set	r	Rings around the center /1*40/
	g	Agricultural goods /corn, wheat, beans/;


parameter	a(r)		Area of ring r
		w(g)		Weight of good g
		theta(g)	Land value share
		d(r)		Distance to ring r
		L		Labor endowment /3000/;

theta(g) = uniform(0,1);
d(r) = ord(r);
a(r) = pi * (sqr(d(r))-sqr(d(r)-1));
w(g) = uniform(0,1);

*	Markets:

*	Labor covers production and transport cost.
*	Land supply greater than or equal to demand for land.
*	Supply of goods equals demand for goods.

*	Hint: Introduce a lower bound on land prices to avoid divide by zero.


execute_unload 'vonthunen.gdx';
$exit;

$ontext
$model:VONTH

$sectors:
	X(g,r)		! Transport of good g from region r
	Y(g,r)		! Production of good g in region r

$commodities:
	P(g)		! Market price of good g
	PL		! Wage rate
	PY(g,r)		! Output price
	PN(r)		! Price of land

$consumers:
	WORKER		! Laborer
	OWNER		! Land owner

$prod:X(g,r)   s:0
	o:P(g)		q:1
	i:PL		q:(d(r)*w(g))
	i:PY(g,r)	q:1

$prod:Y(g,r)   s:1
	o:PY(g,r)	q:1
	i:PN(r)		q:theta(g)	p:1
	i:PL		q:(1-theta(g))	p:1

$report:
	v:DL(g,r)	i:PL	prod:Y(g,r)

$demand:worker  s:1
	d:P(g)		q:1
	e:PL		q:L

$demand:owner  s:1
	d:P(g)		q:1
	e:PN(r)		q:a(r)

$offtext
$sysinclude mpsgeset VONTH

*	Use the wage rate as numeraire:

PL.FX = 1;

$include VONTH.GEN
solve VONTH using mcp;

parameter	pivotdata	Report for display in Excel;
pivotdata("X",g,r) = X.L(g,r);
pivotdata("Y",g,r) = Y.L(g,r);
pivotdata("PY",g,r) = PY.L(g,r)/PL.L;
pivotdata("PN","_",r) = PN.L(r)/PL.L;
pivotdata("P",g,"_") = P.L(g)/PL.L;
pivotdata("AL",g,r)$DL.L(g,r) = DL.L(g,r)/Y.L(g,r);

option pivotdata:3:1:1;
display pivotdata

*.execute_unload 'vonthunen.gdx', pivotdata;
*.execute 'gdxxrw i=vonthunen.gdx o=vonthunen.xlsx par=pivotdata rng=pivotdata!a2 cdim=0';

equations profit_X, profit_Y, market_PL, market_P, market_PN, market_PY;

profit_X(g,r)..		PY(g,r) + (d(r)*w(g))*PL =g= P(g);

profit_Y(g,r)..		PN(r)**theta(g) * PL**(1-theta(g)) =g= PY(g,r);

market_PY(g,r)..	Y(g,r) =g= X(g,r);

market_PL..		L =g= sum((g,r), X(g,r)*d(r)*w(g) + Y(g,r)*(1-theta(g))*PY(g,r)/PL);

market_PN(r)..		a(r) =e= sum(g, Y(g,r)*theta(g)*PL**(1-theta(g))*PN(r)**theta(g))/PN(r) ;

market_P(g)..		sum(r,X(g,r)) =e= (PL*L + sum(r,PN(r)*a(r)))/(card(g)*P(g));

model vtmcp /profit_X.X, profit_Y.Y, market_PL.PL, market_P.P, market_PN.PN, market_PY.PY/;

PN.L(r)	= max(PN.L(r),1e-6);
PN.LO(r) = 1e-6;

vtmcp.iterlim = 0;
solve vtmcp using mcp;

vtmcp.iterlim = 1000;
solve vtmcp using mcp;
