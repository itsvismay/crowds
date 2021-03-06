%read in from the scene file
addpath("../external/smooth-distances/build/");
%fname = "../Scenes/output_results/eight_agents/agent_circle/";
fname = "../Scenes/output_results/three_agents/test/";
%fname = "../Scenes/output_results/scaling_tests/10_agents/";
%fname = "../Scenes/output_results/scaling_tests/test/";

setup_params = jsondecode(fileread(fname+"setup.json"));

scene = struct;
[tV, tF] = readOBJ(fname+setup_params.terrain.mesh);
scene.terrain.V = tV;
scene.terrain.F = tF;
scene.terrain.BF = boundary_faces(tF);
scene.terrain.BVind = unique(scene.terrain.BF);
scene.terrain.BV = tV(scene.terrain.BVind,:);
scene.agents = [];

global Kw Kt Ka
Kw = 0;
Kt = 1000;%kinetic
Ka = 0;

v = [];
e = [];
el = [];
Aeq = [];
beq = [];
A = [];
b = [];
UserTols = [];

%% SETUP DIJIKSTRAS
AdjM = adjacency_matrix(scene.terrain.F);
AdjM_visited = AdjM;
nLayer = 4;
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
%%

a = fieldnames(setup_params.agents);
for i = 1:numel(a)
    agent.id = i;
    agent.xse = getfield(setup_params.agents, a{i}).xse;
    agent.mass = getfield(setup_params.agents, a{i}).mass;
    agent.max_time = agent.xse(end, end);
    agent.waypoints = size(agent.xse,1)-1;
    agent.seg_per_waypoint = 50;
    agent.segments = agent.seg_per_waypoint*agent.waypoints;
    agent.v = 0;
    agent.radius = getfield(setup_params.agents, a{i}).radius;
    
    
    %[r1e, r1v, newA, newA_visited] = set_path3d(newA, newA_visited, agent, scene, VV, EE, nLayer, nTotalVer);
    [r1e, r1v, newA, newA_visited] = set_path3d(newA, newA_visited, agent, scene, VV, EE, nLayer, nTotalVer);
    %edges
    agent.e = r1e;
    r1e = r1e + size(v,1);
    
    e = [e; r1e];
    
    %wiggles the rod start so that they aren't intersecting
    starttime = r1v(1,3);
    endtime = r1v(end,3);
    %r1v(:,3) = ones();%sort(rand(1,size(r1v,1))*(endtime));%r1v(:,3)/i;%
    % smoothing_eps = k*[1,2,3....]
    %adds time to make sure no div by 0 (flat paths)
    smoothing_eps = 1e-1*linspace(1,size(r1v,1), size(r1v,1))'; 
    r1v(:,3) = r1v(:,3) + smoothing_eps;
    r1v(1,3) = starttime;
    %r1v(end,3) = endtime;
    agent.v = r1v;            
    v = [v;r1v];
    
    
    %rest edge lenths
    r1el = sqrt(sum((v(r1e(:,2),:) - v(r1e(:,1))).^2,2));
    el = [el; r1el];
    agent.rest_edge_lengths = r1el;
    agent.rest_region_lengths = [0; r1el(1:size(r1el)-1) + r1el(2:size(r1el))];
    
    %sets up the agent bvh
    [B,I] = build_distance_bvh(agent.v,[]);
    agent.bvh.B = B;
    agent.bvh.I = I;
    
    %fix end points
    num_constraints = size(agent.xse,1)*2 +1;
    Aeq_rows = [1:num_constraints];
    Aeq_cols = [1:3 reshape([3*agent.seg_per_waypoint*linspace(1,agent.waypoints,agent.waypoints) + 1; 
                3*agent.seg_per_waypoint*linspace(1,agent.waypoints,agent.waypoints) + 2], 1,[])];
    Aeq_vals = ones(1,num_constraints);
    
    A1eq = sparse(Aeq_rows, Aeq_cols, Aeq_vals, num_constraints, numel(r1v));
    b1eq = [r1v(1,:)'; reshape(r1v(end,1:2)', 1, [])'];
    
    Aeq = [Aeq zeros(size(Aeq,1), size(A1eq,2)); 
            zeros(size(A1eq,1), size(Aeq,2)) A1eq];
        
    beq = [beq; b1eq];

    %time is monotonic constraints 
    %t_i+1 - t_i > 0 --> in this format --> A1*q <= 0
    A1 = sparse(reshape([1:agent.segments; 1:agent.segments], 1, 2*agent.segments),...
                reshape([3:3:(numel(r1v)-3); 6:3:(numel(r1v))], 1, 2*agent.segments),...
                reshape([ones(1, agent.segments); -ones(1,agent.segments)], 1, 2*agent.segments),... 
                agent.segments, numel(r1v));
    b1 = zeros(agent.segments, 1);

    %max time via inequality constraint (comment out to turn off, but make sure
    %you uncomment the end time potential energy in cost)
    A1 = [A1; zeros(1, 3*agent.segments+2) 1];
    b1 = [b1; agent.max_time];
    
    A = [A zeros(size(A,1), size(A1,2));
        zeros(size(A1,1), size(A,2)) A1];
    b = [b; b1];
    
    scene.agents = [scene.agents agent];   
    UserTols = [UserTols agent.radius];
end
Aeq = [Aeq zeros(size(Aeq,1),numel(scene.agents))];
A = [A zeros(size(A,1),numel(scene.agents))];


PV = v;
PE = e;
[CV,CF,CJ,CI] = edge_cylinders(PV,PE, 'Thickness',0.5, 'PolySize', 10);
figure;
surf_anim = tsurf(CF, CV); 
axis equal;
drawnow;

%minimize here
% options = optimoptions('fmincon', 'SpecifyObjectiveGradient', true, 'SpecifyConstraintGradient',true, 'Display', 'iter', 'UseParallel', false, 'HessianApproximation', 'lbfgs');
options = optimoptions('fmincon', 'SpecifyObjectiveGradient', true, 'SpecifyConstraintGradient',true, 'Display', 'iter', 'UseParallel', false);
options.MaxFunctionEvaluations = 1e6;
options.MaxIterations = 1e3;
q_i  = [reshape(v', numel(v),1);  -1e-8*ones(numel(scene.agents),1)];
TRUEQI = q_i;
[q_i, fval, exitflag, output] = fmincon(@(x) path_energy(x, UserTols, numel(scene.agents), scene, e, surf_anim),... 
                            q_i, ...
                            A,b,Aeq,beq,[],[], ...
                            @(x)nonlinear_constraints(x, UserTols, scene), options);
q = q_i(1:end-numel(scene.agents));
                        
PV = reshape(q, 3, numel(q)/3)';
[CV,CF,CJ,CI] = edge_cylinders(PV,e, 'Thickness',0.25, 'PolySize', 10);
surf_anim.Vertices = CV;
drawnow;


function [f,g] = path_energy(q_i, UserTols, num_agents, scene, e, surf_anim)
    global Kw Kt Ka;

    q = q_i(1:end-num_agents);
    Q = reshape(q, numel(q)/num_agents, num_agents); %3*nodes x agents
    Tols = q_i(end-num_agents+1:end);

    T = 0;
    W = 0;
    
    g = zeros(size(q_i));
    GT = zeros(size(Q));
    for i=1:num_agents
        q_i = Q(:, i); %3*nodes
        m = 1; %scene.agents(i).mass;
        dx = reshape(q_i(4:end) - q_i(1:end -3), 3, numel(q_i)/3-1)';
        T = T + Kt*sum(0.5*m*sum(dx(:, 1:2).*dx(:,1:2),2)./dx(:,3)); %kinetic energy
        dEdq_left = zeros(numel(q_i)/3, 3);
        dEdq_right = zeros(numel(q_i)/3, 3);

        dEdq_left(1:end-1,1) = -m*dx(:,1)./dx(:,3);
        dEdq_left(1:end-1,2) = -m*dx(:,2)./dx(:,3);
        dEdq_left(1:end-1,3) = 0.5*m*(dx(:,1).*dx(:,1) + dx(:,2).*dx(:,2))./(dx(:,3).*dx(:,3));

        dEdq_right(2:end, 1) = m*dx(:,1)./dx(:,3);
        dEdq_right(2:end, 2) = m*dx(:,2)./dx(:,3);
        dEdq_right(2:end, 3) = -0.5*m*(dx(:,1).*dx(:,1) + dx(:,2).*dx(:,2))./(dx(:,3).*dx(:,3));

        dEdq = dEdq_left + dEdq_right;
        
        GT(:,i) = Kt*reshape(dEdq', size(dEdq,1)*size(dEdq,2), 1);
        
    end
    
    W = 0.5*(Kw.*(Tols - UserTols'))'*(Tols - UserTols');
    
    gT = reshape(GT, size(GT,1)*size(GT,2),1);
    gW = Kw.*(Tols - UserTols');
    g(1:end-num_agents) = gT;
    g(end-num_agents+1:end) = gW;
    %find minimum energy curve
    f = T+W;
    
%     PV = reshape(q, 3, numel(q)/3)';
%     PE = e;
%     [CV,CF,CJ,CI] = edge_cylinders(PV,PE, 'Thickness',0.25, 'PolySize', 4);
%     surf_anim.Vertices = CV;
%     drawnow;
    

end