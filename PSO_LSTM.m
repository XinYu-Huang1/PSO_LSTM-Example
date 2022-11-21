%% ����Ⱥ�Ż�LSTM(PSO_LSTM)
clc
clear
close  all
%% ���ݶ�ȡ
geshu=200;%ѵ�����ĸ���
%��ȡ����
shuru=xlsread('input.xlsx');
shuchu=xlsread('output.xlsx');
nn = randperm(size(shuru,1));%�������
% nn=1:size(shuru,1);%��������
input_train =shuru(nn(1:geshu),:);
input_train=input_train';
output_train=shuchu(nn(1:geshu),:);
output_train=output_train';
input_test =shuru(nn((geshu+1):end),:);
input_test=input_test';
output_test=shuchu(nn((geshu+1):end),:);
output_test=output_test';
%��������������ݹ�һ��
[aa,bb]=mapminmax([input_train input_test]);
[cc,dd]=mapminmax([output_train output_test]);
global inputn outputn shuru_num shuchu_num XValidation YValidation
[inputn,inputps]=mapminmax('apply',input_train,bb);
[outputn,outputps]=mapminmax('apply',output_train,dd);
shuru_num = size(input_train,1); % ����ά��
shuchu_num = 1;  % ���ά��
dam = 10; % ��֤����������֤���Ǵ�ѵ��������ȡ������
idx = randperm(size(inputn,2),dam);
XValidation = inputn(:,idx);
inputn(:,idx) = [];
YValidation = outputn(idx);
outputn(idx) = [];
YValidationy = output_train(idx);
output_train(idx) = [];
%%
% 1. Ѱ����Ѳ���
NN=5;                   %��ʼ��Ⱥ�����
D=2;                    %��ʼ��Ⱥ��ά����
T=10;                   %��ʼ��Ⱥ�����������
c1=2;                   %ѧϰ����1
c2=2;                   %ѧϰ����2
%�����Եݼ���������Ⱥ�㷨
Wmax=1.2; %����Ȩ�����ֵ
Wmin=0.8; %����Ȩ����Сֵ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ÿ��������ȡֵ��Χ
ParticleScope(1,:)=[10 200];  % �м����Ԫ����
ParticleScope(2,:)=[0.01 0.15]; % ѧϰ��
ParticleScope=ParticleScope';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xv=rand(NN,2*D); %���ȣ���ʼ����Ⱥ�����ٶȺ�λ��
for d=1:D
    xv(:,d)=xv(:,d)*(ParticleScope(2,d)-ParticleScope(1,d))+ParticleScope(1,d);  
    xv(:,D+d)=(2*xv(:,D+d)-1 )*(ParticleScope(2,d)-ParticleScope(1,d))*0.2;
end
x1=xv(:,1:D);%λ��
v1=xv(:,D+1:2*D);%�ٶ�
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------��ʼ������λ�ú���Ӧ��ֵ-----------------
p1=x1;
pbest1=ones(NN,1);
for i=1:NN
    pbest1(i)=fitness(x1(i,:));
end
%------��ʼʱȫ������λ�ú�����ֵ---------------
gbest1=min(pbest1);
lab=find(min(pbest1)==pbest1);
g1=x1(lab,:);
gb1=ones(1,T);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-----������ѭ�������չ�ʽ���ε���ֱ����������---
% N=40;                   %��ʼ��Ⱥ�����
% D=10;                   %��ʼ��Ⱥ��ά��
% T=100;                 %��ʼ��Ⱥ�����������
for i=1:T
    for j=1:NN
        if (fitness(x1(j,:))<pbest1(j))
            p1(j,:)=x1(j,:);%����
            pbest1(j)=fitness(x1(j,:));
        end
        if(pbest1(j)<gbest1)
            g1=p1(j,:);%����
            gbest1=pbest1(j);
        end
         w=Wmax-(Wmax-Wmin)*i/T;          
         v1(j,:)=w*v1(j,:)+c1*rand*(p1(j,:)-x1(j,:))+c2*rand*(g1-x1(j,:));
         x1(j,:)=x1(j,:)+v1(j,:); 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%λ��Լ��
        label=find(x1(j,:)>ParticleScope(2,:));
        x1(j,label)=ParticleScope(2,label);        
        label2=find(x1(j,:)<ParticleScope(1,:));
        x1(j,label2)=ParticleScope(1,label2);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%�ٶ�Լ��                
        labe3=find(v1(j,:)>ParticleScope(2,:)*0.2);
        v1(j,labe3)=ParticleScope(2,labe3)*0.2;        
        label4=find(v1(j,:)<-ParticleScope(2,:)*0.2);
        v1(j,label4)=-ParticleScope(2,label4)*0.2;              
    end
        %         gb1(i)=min(pbest1);
        gb1(i)=gbest1;
end
zhongjian1_num = round(g1(1));  
xue = g1(2);
%% ģ�ͽ�����ѵ��
layers = [ ...
    sequenceInputLayer(shuru_num)    % �����
    lstmLayer(zhongjian1_num)        % LSTM��
    fullyConnectedLayer(shuchu_num)  % ȫ���Ӳ�
    regressionLayer];
 
options = trainingOptions('adam', ...  % �ݶ��½�
    'MaxEpochs',50, ...                % ����������
    'GradientThreshold',1, ...         % �ݶ���ֵ 
    'InitialLearnRate',xue,...
    'Verbose',0, ...
    'Plots','training-progress','ValidationData',{XValidation,YValidation});
%% ѵ��LSTM
net = trainNetwork(inputn,outputn,layers,options);
%% Ԥ��
net = resetState(net);% ����ĸ���״̬���ܶԷ�������˸���Ӱ�졣��������״̬���ٴ�Ԥ�����С�
[~,Ytrain]= predictAndUpdateState(net,inputn);
test_simu=mapminmax('reverse',Ytrain,dd);%����һ��
%���Լ���������������ݹ�һ��
inputn_test=mapminmax('apply',input_test,bb);
[net,an]= predictAndUpdateState(net,inputn_test);
test_simu1=mapminmax('reverse',an,dd);%����һ��
error1=test_simu1-output_test;%���Լ�Ԥ��-��ʵ
[~,Ytrain]= predictAndUpdateState(net,XValidation);
test_simuy=mapminmax('reverse',Ytrain,dd);%����һ��
%% ��ͼ
figure
plot(output_train,'r-o','Color',[255 0 0]./255,'linewidth',0.8,'Markersize',4,'MarkerFaceColor',[255 0 0]./255)
hold on
plot(test_simu,'-s','Color',[0 0 0]./255,'linewidth',0.8,'Markersize',5,'MarkerFaceColor',[0 0 0]./255)
hold off
legend(["��ʵֵ" "Ԥ��ֵ"])
xlabel("����")
title("ѵ����")

figure
plot(YValidationy,'-o','Color',[255 255 0]./255,'linewidth',0.8,'Markersize',4,'MarkerFaceColor',[255 0 0]./255)
hold on
plot(test_simuy,'-s','Color',[0 0 0]./255,'linewidth',0.8,'Markersize',5,'MarkerFaceColor',[0 0 0]./255)
hold off
legend(["��ʵֵ" "Ԥ��ֵ"])
xlabel("����")
title("��֤��")

figure
plot(output_test,'-o','Color',[0 0 255]./255,'linewidth',0.8,'Markersize',4,'MarkerFaceColor',[25 0 255]./255)
hold on
plot(test_simu1,'-s','Color',[0 0 0]./255,'linewidth',0.8,'Markersize',5,'MarkerFaceColor',[0 0 0]./255)
hold off
legend(["��ʵֵ" "Ԥ��ֵ"])
xlabel("����")
title("���Լ�")

 % ��ʵ���ݣ�������������������������������output_test = output_test;
T_sim_optimized = test_simu1;  % ��������

num=size(output_test,2);%ͳ����������
error=T_sim_optimized-output_test;  %�������
mae=sum(abs(error))/num; %����ƽ���������
me=sum((error))/num; %����ƽ���������
mse=sum(error.*error)/num;  %����������
rmse=sqrt(mse);     %�����������
% R2=r*r;
tn_sim = T_sim_optimized';
tn_test =output_test';
N = size(tn_test,1);
R2=(N*sum(tn_sim.*tn_test)-sum(tn_sim)*sum(tn_test))^2/((N*sum((tn_sim).^2)-(sum(tn_sim))^2)*(N*sum((tn_test).^2)-(sum(tn_test))^2)); 

disp(' ')
disp('----------------------------------------------------------')

disp(['ƽ���������maeΪ��            ',num2str(mae)])
disp(['ƽ�����meΪ��            ',num2str(me)])
disp(['��������rmseΪ��             ',num2str(rmse)])
disp(['���ϵ��R2Ϊ��                ' ,num2str(R2)])







































