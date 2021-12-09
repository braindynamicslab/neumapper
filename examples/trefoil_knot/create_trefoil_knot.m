function [X,d] = create_trefoil_knot(n, metric_type)
    t = 2*pi*[1:n]./n;
    x = sin(t)+2*sin(2*t);
    y = cos(t)-2*cos(2*t);
    z = -sin(3*t);
    X = [x' y' z'];
    d = squareform(pdist(X, metric_type));
    
end