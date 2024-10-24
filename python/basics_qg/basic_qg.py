

import sympy as sp
# symbols
a, d, p, q = sp.symbols('a d p q')

# population mean
mu = p**2 * a + 2*p*(1-p) * d + (1-p)**2 * (-a)
simplified_mu = sp.simplify(mu)

# Collect terms

collected_mu = sp.collect(simplified_mu, [a, d])
collected_mu

# access second summand
# Access the second summand
second_summand = collected_mu.args[1]

# factor second summand
second_summand_factored_p = sp.factor(second_summand, p)
second_summand_factored_p

# put together
factored_mu_p = collected_mu.args[0] + second_summand_factored_p
factored_mu_p

