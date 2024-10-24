# second improvement
import sympy as sp

# Step 1: Define symbolic dimensions for the design matrix
n, p = sp.symbols('n p', integer=True)

# Step 2: Define the design matrix X, coefficient vector beta, and response vector y
X = sp.MatrixSymbol('X', n, p)  # X is a matrix with n rows and p columns
beta = sp.MatrixSymbol('beta', p, 1)  # beta has p rows and 1 column
y = sp.MatrixSymbol('y', n, 1)  # y has n rows and 1 column

# Step 3: Compute the normal equation: X.T * X * beta = X.T * y
X_T = X.T  # Transpose of X
normal_eq_left = X_T * X * beta  # Left side of the normal equation
normal_eq_right = X_T * y  # Right side of the normal equation

# Step 4: Solve for beta: beta = (X.T * X)^-1 * X.T * y
# Assuming (X.T * X) is invertible
beta_est = sp.simplify(sp.Inverse(X_T * X) * normal_eq_right)

# Output the result
beta_est



# improved version
import sympy as sp

# Define symbolic dimensions for the design matrix
n, p = sp.symbols('n p', integer=True)

# Define the design matrix X with symbolic dimensions (n rows, p columns)
X = sp.MatrixSymbol('X', n, p)

# Define the coefficient vector beta and response vector y
beta = sp.MatrixSymbol('beta', p, 1)  # beta has p rows (one for each feature) and 1 column
y = sp.MatrixSymbol('y', n, 1)  # y has n rows (one for each observation) and 1 column

# Continue with the rest of your symbolic least squares derivation
residual = y - X * beta
S = residual.T * residual  # Sum of squared residuals
S_diff = sp.simplify(sp.diff(S, beta))

# Solve the normal equation
beta_est = sp.solve(sp.Eq(S_diff, 0), beta)
beta_est
# []
# seams to give an empty solution






# ===
import sympy as sp
 
# Step 1: Define the symbols
X = sp.MatrixSymbol('X', None, None)  # Design matrix (can have any size)

Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/Users/pvr/Library/Python/3.9/lib/python/site-packages/sympy/matrices/expressions/matexpr.py", line 680, in __new__
    n, m = _sympify(n), _sympify(m)
  File "/Users/pvr/Library/Python/3.9/lib/python/site-packages/sympy/core/sympify.py", line 529, in _sympify
    return sympify(a, strict=True)
  File "/Users/pvr/Library/Python/3.9/lib/python/site-packages/sympy/core/sympify.py", line 388, in sympify
    raise SympifyError(a)
sympy.core.sympify.SympifyError: SympifyError: None


