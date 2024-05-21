function bestParticleArray = get_nondominated_solutions(particleArray)
%GET_NONDOMINATED_SOLUTIONS 计算非支配解集
%   从给定粒子群中，提取一组非支配解集，并以粒子数组形式返回
arguments
    particleArray (1, :) Particle % 粒子群（一维Particle数组）
end

% 初始化非支配解粒子数组
bestParticleArray = particleArray(1);

for index = 2:length(particleArray)
    particleA = particleArray(index); % 新考察的粒子
    flag = false; % 是否将新粒子加入非支配解集
    deleteingIndex = []; % 需要从非支配解集中删除的粒子索引

    for j = 1:length(bestParticleArray)
        particleB = bestParticleArray(j); % 已在非支配解集中的粒子
        if Particle.judge_dominance( ...
                particleA.fitness_value, particleB.fitness_value)
            % 新考察的粒子支配某个已在非支配解集中的粒子，
            % 将新考察的粒子A加入非支配解集，并从非支配解集中删除另一个粒子B
            flag = true;
            deleteingIndex = [deleteingIndex, j]; %#ok<AGROW>
        elseif Particle.judge_dominance( ...
                particleB.fitness_value, particleA.fitness_value)
            % 新考察的粒子被支配，什么都不做
            continue
        else
            % 新考察的粒子与非支配解集中的粒子都互不支配，
            % 将新考察的粒子加入非支配解集
            flag = true;
        end
    end

    if flag
        % 删去待删除的粒子
        logicIndex = true(size(bestParticleArray));
        logicIndex(deleteingIndex) = false;
        bestParticleArray = bestParticleArray(logicIndex);

        % 将新粒子加入非支配解集
        bestParticleArray = [bestParticleArray, index]; %#ok<AGROW>
    end
end
