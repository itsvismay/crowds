function [Dist,Path, CDATA] = mydijk(Q, A, s, t, Bind)
    n = size(A, 1);

    Qlabel = linspace(1, size(Q,1), size(Q,1));
    CDATA = full(sum(A))';
    D = Inf*ones(n,1); 
    D(s) = 0;
    P = -1*ones(n,1);

	while length(Qlabel)>0
        [d, ind]= min(D(Qlabel));
        u = Qlabel(ind);
        Qlabel(ind) = [];
    
        [neighbors,kA,Aj] = find(A(:,u));
        for vi = neighbors'
            edge_weight = 1;
            
            if(any(ismember([u, vi], Bind)))
                %both are edge vertices
                edge_weight = 10000;
            end
            alt_dist = D(u) + edge_weight*norm(Q(u,:) - Q(vi,:));
            if alt_dist < D(vi)
                D(vi) = alt_dist;
                P(vi) = u;
            end
        end
    end


    Dist = D(t);
    b = t;
    Path = [];
    while P(b)>0 && b ~= s
        Path = [b Path];
        b = P(b);
    end
    Path = [s Path];
       
    
end