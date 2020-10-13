x_field = 10;
y_field = 10;
max_time = 10;
segments = 10;

%vertices
r1v = [0*linspace(0,x_field,segments+1)', 0*linspace(0,y_field,segments+1)', linspace(0,max_time,segments+1)'];
%edges
r1e = [linspace(1,segments,segments)', linspace(2,segments+1,segments)'];
%rest edge lenths
r1el = sqrt(sum((r1v(r1e(:,2),:) - r1v(r1e(:,1))).^2,2));
%compute kb
r1kb = ComputeKB(r1v, r1e, r1el);
%rest region lenghts
r1l = [0; r1el(1:size(r1el)-1) + r1el(2:size(r1el))];

%SOLVE RODS FOR: max utility

% % %Idea: max utility = min curvature -> min f(x) with fixed t's
% % % minimize RodLength(x) 
% % %   s.t. [x_n, y_n] = goal_location and [x_1, y_1] = start_location
% % %block out t coordinates [x,y,t,x,y,t...]
% % v0 = reshape(r1v',[size(r1v,1)*size(r1v,2),1]);
% % C = eye(size(v0, 1));
% % C(3*linspace(1,size(v0,1)/3,size(v0,1)/3),:) = [];
% % x0 = zeros(size(C,1),1);
% % rod_length = RodLength(x0, C, v0,r1e,0);
% % Aeq = zeros(4, size(x0,1)); %picks out [x_n, y_n]
% % Aeq(1:2, 1:2) = eye(2);
% % Aeq(3:4, size(x0,1)-1:size(x0,1)) = eye(2);
% % b = [0,0,10,9]; %[start location, goal location]
% % b = b' - Aeq*C*v0;
% % Energy = @(x)RodLength(x, C, v0,r1e,0);
% % x = fmincon(Energy,x0,[],[],Aeq, b);
% % v = C'*x + v0;
% % r1v = reshape(v, [3,size(v,1)/3]);
% % r1v = r1v';
% % TotalEnergy(x, C, v0, r1e,1);



%Idea: max utility = min rod length + kinetic energy -> min L(x, t) + KE(x, t)
% minimize RodLength(x,t) + KE(x,t)
%   s.t. [x_n, y_n] = goal_location and t_i<t_i+1
v0 = reshape(r1v',[size(r1v,1)*size(r1v,2),1]);
C = eye(size(v0, 1));
x0 = zeros(size(C,1),1);
rod_length = RodLength(x0, C, v0,r1e,0);

%Equality constraints for boundary conditions
Aeq = zeros(6, size(x0,1)); %picks out [x1, y_1, t_1, x_n, y_n, t_n]
Aeq(1:3, 1:3) = eye(3);
Aeq(4:6, size(x0,1)-2:size(x0,1)) = eye(3);
beq = [0,0,0,10,9,10]; %[start_x, start_y, start_t, goal_x, goal_y, goal_t]
beq = beq' - Aeq*v0;

%Equality constraints for roomba
% Aeq = zeros(3*4, size(x0,1)); %picks out [x1, y_1, t_1, x_n, y_n, t_n]
% Aeq(1:3, 1:3) = eye(3); %start 
% Aeq(4:6, 10:12) = eye(3); %t1
% Aeq(7:9, 19:21) = eye(3); %t2
% Aeq(10:12, size(x0,1)-2:size(x0,1)) = eye(3); %end
% beq = [0,0,0, 5,0,3, 5,0,6, 10,9,10]; %[x0,y0,t0, x1,y1, t1, x2, y2,t2, xn, yn, tn]
% beq = beq' - Aeq*v0;

%%Inequality constraints so that t1<=t2.....
A = zeros( size(x0, 1)/3 - 1, size(x0,1));
for i=1:size(A,1)
    A(i, 3*i) = -1;
    A(i, 3*i+3) = 1;
end
A = -A;
b = -A*v0;

Energy = @(x) TotalEnergy(x, C, v0, r1e, 0);
x = fmincon(Energy,x0,A,b,Aeq, beq);
v = C'*x + v0;
r1v = reshape(v, [3,size(v,1)/3]);
r1v = r1v';
TotalEnergy(x, C, v0, r1e,1);

%%%%%

PV = r1v;
PE = r1e;
[CV,CF,CJ,CI] = edge_cylinders(PV,PE, 'Thickness',1, 'PolySize', 10);
%PLOT AGENTS
figure('Name', 'Simple collision');
tsurf(CF, CV);

hold on;

for ti=1:segments
    clf;
    tsurf(CF, CV);
    hold on;
    
    %agent 1
    ax = r1v(ti,1);
    ay = r1v(ti,2);
    plot3(ax,ay,0,'go', 'LineWidth',3,'MarkerSize', 15);
    hold on;
    
    %plotting, imaging
    [imind, cm] = rgb2ind(frame2im(getframe(gcf)), 256);
    if ti == 1 
        imwrite(imind, cm,'./simple_collision.gif','gif', 'DelayTime',0.1, 'Loopcount',inf); 
    else
        imwrite(imind, cm,'./simple_collision.gif','gif','DelayTime',0.1, 'WriteMode','append');
    end
    
end

function [te] = TotalEnergy(x, C, v0, r1e, prnt)
    rl = RodLength(x, C, v0, r1e, prnt);
    ke = KineticEnergy(x, C, v0, r1e, prnt);
    te = rl + 0;
end

function [rl] = RodLength(x, C, v0, edges, prnt)
    v = C'*x + v0;
    verts = reshape(v, [3,size(v,1)/3])';
    rl = 0;
    for i=1:size(edges,1)
        rl = rl + norm(verts(edges(i,2),:) - verts(edges(i,1),:));
    end
%     rl = sum(sqrt(sum((verts(edges(:,2),:) - verts(edges(:,1),:)).^2,2)));
    if prnt
        rl
    end
end

function [ke] = KineticEnergy(x, C, v0, edges, prnt)
    ke = 0;
    v = C'*x + v0;
    verts = reshape(v, [3,size(v,1)/3])';
    %0.5*m*v^2
    m = 1;
    for i=1:size(edges,1)
        dx = norm(verts(edges(i,2),1:2) - verts(edges(i,1),1:2)); %dx
        dt = verts(edges(i,2),3) - verts(edges(i,1),3);
        ke_s = 0.5*m*(dx/dt)*(dx/dt)*dt;
        if prnt
            fprintf("%2.4f, %2.4f, %2.4f\n", dx, dt, ke_s);
        end
        ke = ke + ke_s;
    end
    ke
end

function [be] = BendEnergy(x, C, v0, e, el, restRegionLengths)
    v = C'*x + v0;
    v1 = reshape(v, [3,size(v,1)/3]);
    v1 = v1';
    kb = ComputeKB(v1, e, el);
    
    %bending modulus 
    alpha = 1;
    be = 0;
    for i = 2:size(kb,1)
        be = be + (alpha*dot(kb(i,:),kb(i,:))/restRegionLengths(i));
    end
end


function [kb] = ComputeKB(verts, edges, restEdgeLengths)
    E = (verts(edges(:,2),:) - verts(edges(:,1)));
    e_i_1 = E(1:size(edges,1)-1,:);
    e_i = E(2:size(edges,1),:);
    l_i_1 = restEdgeLengths(1:size(edges,1)-1);
    l_i = restEdgeLengths(2:size(edges,1));
    kb = [[0 0 0]; cross(e_i_1, e_i)./(l_i_1.*l_i + dot(e_i, e_i_1,2))];
end

function [se] = StretchEnergy(verts, edges, restEL)
    ym = 1e4;
    rod_rad = 0.5;
    se = 0;
    
    for i = 1:size(edges,1)
        l = sqrt(sum((verts(edges(:,2),:) - verts(edges(:,1))).^2,2));
        eps = (l - restEL(i))/restEL(i);
        se = se + 0.5*ym*rod_rad*rod_rad*pi*eps*eps;
    end
end