%read in from the scene file
addpath("../external/smooth-distances/build/");
%fname = "../Scenes/output_results/eight_agents/agent_circle/";
%fname = "../Scenes/output_results/three_agents/test/";
fname = "../Scenes/output_results/scaling_tests/20_agents/";
%fname = "../Scenes/output_results/scaling_tests/test/";

setup_params = jsondecode(fileread(fname+"setup.json"));
global scene;
scene = struct;
[tV, tF] = readOBJ(fname+setup_params.terrain.mesh);
scene.terrain.V = tV;
scene.terrain.F = tF;
scene.terrain.BF = boundary_faces(tF);
scene.terrain.BVind = unique(scene.terrain.BF);
scene.terrain.BV = tV(scene.terrain.BVind,:);
scene.agents = [];

global n_segments waypoints;
n_segments = 50;
waypoints = 1;

q = [];
lb = [];

Aeq = [];
beq = [];
A = [];
b = [];
UserTols = [];
coefficients_matrix = zeros(6, numel(fieldnames(setup_params.agents)));

%% SETUP DIJIKSTRAS
AdjM = adjacency_matrix(scene.terrain.F);
AdjM_visited = AdjM;
nLayer = 15;
nTotalVer = nLayer * length(scene.terrain.V(:,1));
% build up 3d graph
% find all the edges in 2d graph
A_lt = tril(AdjM);
[edge_s,edge_t] = find(A_lt);
edge = zeros(length(edge_s),2);
edge(:,1) = edge_s;
edge(:,2) = edge_t;
    
% set the num of layer and get the spacetime graph 
% (vertices: VV and edges: EE)
time = linspace(0,1,nLayer)';
[VV,EE, newA] = spacetime_graph(scene.terrain.V,edge,time);


% make the graph directed along the time dimension
[ii,jj,ss] = find(newA);
for k=1:length(ii)
   s_temp = ii(k);
   t_temp = jj(k);
   if VV(s_temp,3) > VV(t_temp,3)
       %newA(s_temp, t_temp) = 0;
   end
end

newA_visited = newA;

%% Initialize agents
a = fieldnames(setup_params.agents);
for i = 1:numel(a)
    %agent properties
    agent.id = i;
    agent.xse = getfield(setup_params.agents, a{i}).xse;
    agent.mass = getfield(setup_params.agents, a{i}).mass;
    agent.max_time = agent.xse(end, end);
    
    agent.radius = getfield(setup_params.agents, a{i}).radius;
    
    agent.mass = getfield(setup_params.agents, a{i}).mass;
    agent.friends = getfield(setup_params.agents, a{i}).friends;
    agent.mesh = getfield(setup_params.agents, a{i}).mesh;
    agent.animation_cycles = getfield(setup_params.agents, a{i}).animation_cycles;
    
    
    %[r1e, r1v, newA, newA_visited] = set_path3d(newA, newA_visited, agent, scene, VV, EE, nLayer, nTotalVer);
    [r1e, r1v, newA, newA_visited] = set_path3d(newA, newA_visited, agent, scene, VV, EE, nLayer, nTotalVer, n_segments);
  
    
    %wiggles the rod start so that they aren't intersecting
    starttime = r1v(1,3);
    endtime = r1v(end,3);
    %r1v(:,3) = ones();%sort(rand(1,size(r1v,1))*(endtime));%r1v(:,3)/i;%
    % smoothing_eps = k*[1,2,3....]
    %adds time to make sure no div by 0 (flat paths)
    smoothing_eps = 1e-1*linspace(1,size(r1v,1), size(r1v,1))'; 
    r1v(:,3) = r1v(:,3) + smoothing_eps;
    r1v(1,3) = starttime;
    
    %set the 3rd dimesion values to 1/dt fromm t
    dt1 = r1v(2:end,3) - r1v(1:end-1,3); %get the delta times
    
    %0. Set boundaries
    p0 = [r1v(1,1:2) 0];
    pn = [r1v(end,1:2), 100];
    
    %1. DOFS [...; agent_x, agent_y, agent_dt; ...;]----> size: [seg+1, seg+1, seg]
    q = [q; r1v(:,1); r1v(:,2); 1./dt1]; 
    
    %2. Bounds on times
    lb = [lb; -inf(2*size(r1v,1),1); zeros(size(dt1,1),1)];
        
    %3. Equality constraints
    %fix end points equality constraint set 1
    dofs_per_agent = 2*(n_segments + 1) + n_segments;
    nverts = n_segments +1;
    A1eq = zeros(5, dofs_per_agent); 
    A1eq(1,1) = 1; %fix x0
    A1eq(2,nverts+1) = 1; %fix  y0
    A1eq(3,nverts) = 1; %fix xn
    A1eq(4,2*nverts) = 1; %fix yn
    A1eq(5, (2*nverts+1):end) = 1; %sum(1/dt)
    b1eq = [p0(1:2) pn(1:2) pn(3)]';
    
    Aeq = [Aeq zeros(size(Aeq,1), size(A1eq,2)); 
                zeros(size(A1eq,1), size(Aeq,2)) A1eq];
    beq = [beq; b1eq];
    
    %4. Inequality constraints
    nsegments = n_segments;
    A1 = zeros(1, 2*nverts+nsegments);
    A1((2*nverts+1):end) = 1;

    b1 = sum(1./dt1);
    
    A = [A zeros(size(A,1), size(A1,2)); 
                zeros(size(A1,1), size(A,2)) A1];
    b = [b; b1];
    
    
    scene.agents = [scene.agents agent];   
    UserTols = [UserTols agent.radius];
end

%% Optimization
% ._._._._._.

plot_curves(q);

options = optimoptions(@fmincon,'Algorithm','interior-point',...
                       'SpecifyObjectiveGradient',true,'SpecifyConstraintGradient',false,...
                       'MaxIterations', 1e9,...
                       'MaxFunctionEvaluations', 1e9, ...
                       'Display', 'iter', ...
                       'HessianApproximation', 'finite-difference',...
                       'SubproblemAlgorithm', 'cg');
                

                        
%minimize with KE here
%user constraint set 2

[qn, fval,exitflag,output,lambda, grad,hessian] = fmincon(@(x) energy(x),... 
                            q, ...
                            A,b,Aeq,beq,lb,[], ...
                            [], options);
plot_curves(qn);
%%

function [T, g] = energy(Q)
    
    global n_segments scene
    nverts = n_segments + 1;
    T = 0;
    g = zeros(size(Q));
    for i = 1:numel(scene.agents)
        dofs_per_agent = 2*(n_segments + 1) + n_segments;        
        q = Q((i-1)*dofs_per_agent +1: i*dofs_per_agent);
        
        r = 10;
        u = [q(1:nverts) q((nverts+1):2*nverts)];
        it = q((2*nverts+1):end);

        du = u(2:end,:) - u(1:(end-1),:);
        T = T + 0.5*sum(sum((du.*du).*(it*r)));


        %l = du + 
        %need some inverse length weighting to stabilize
        %T = T + 0.5*sum(sum((du.*du)*r)) + 0.5*sum(it);
        
        e = ones(n_segments,1);
        D = spdiags([-e e],0:1,n_segments,nverts);
        if nargout > 1
            grad = r*(D'*D)*u;
            grad = [grad(:);sign(it)]; %real gradient
        end
        g((i-1)*dofs_per_agent +1: i*dofs_per_agent) = grad;
    end

end

function h = plot_curves(Q)
    global n_segments scene
    n_verts = n_segments + 1;
    PV = [];
    PE = [];
    for i = 1:numel(scene.agents)
        dofs_per_agent = 2*(n_segments + 1) + n_segments;
        e = [(1:n_segments)' (2:(n_segments+1))'];
        PE = [PE; e + size(PV,1)];
        
        q = Q((i-1)*dofs_per_agent +1: i*dofs_per_agent);
        v = zeros(n_verts, 3);
        v(:,1) = q(1:n_verts);
        v(:,2) = q(n_verts+1:2*n_verts);
        dt = 1./q(2*n_verts +1: end);
        v(2:end, 3) = cumsum(dt);
        PV = [PV; v];
        
    end
   
    
    
    [CV,CF,CJ,CI] = edge_cylinders(PV,PE, 'Thickness',1, 'PolySize', 4);
    surf_anim = tsurf(CF, CV); 
    axis equal;
    drawnow;
end
