% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                           %
%    incidenceIndepDecomp                                                   %
%                                                                           %
%                                                                           %
% OUTPUT: Returns the finest nontrivial incidence independent decomposition %
%    of a chemical reaction network (CRN), if it exists. If no such         %
%    decomposition exists, a message appears saying so. The output          %
%    variables 'model', 'I_a', 'G', and 'P' allow the user to view the      %
%    following, respectively:                                               %
%       - Complete network with all the species listed in the 'species'     %
%            field of the structure 'model'                                 %
%       - Incidence matrix of the network                                   %
%       - Undirected graph of I_a                                           %
%       - Partitions representing the decomposition of the reactions        %
%                                                                           %
% INPUT: model: a structure, representing the CRN (see README.txt for       %
%    details on how to fill out the structure)                              %
%                                                                           %
% References:                                                               %
%    [1] Hernandez B, Amistas D, De la Cruz R, Fontanil L, de los Reyes V   %
%           A, Mendoza E (2022) Independent, incidence independent and      %
%           weakly reversible decompositions of chemical reaction networks. %
%           MATCH Commun Math Comput Chem, 87(2):367-396.                   %
%           https://doi.org/10.46793/match.87-2.367H                        %
%    [2] Hernandez B, De la Cruz R (2021) Independent decompositions of     %
%           chemical reaction networks. Bull Math Biol 83(76):1–23.         %
%           https://doi.org/10.1007/s11538-021-00906-3                      %
%    [3] Soranzo N, Altafini C (2009) ERNEST: a toolbox for chemical        %
%           reaction network theory. Bioinform 25(21):2853–2854.            %
%           https://doi.org/10.1093/bioinformatics/btp513                   %
%                                                                           %
% Created: 12 June 2024                                                     %
% Last Modified: 13 June 2024                                               %
%                                                                           %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %



function [model, I_a, G, P] = incidenceIndepDecomp(model)
    
    %
    % Step 1: Create a list of all species indicated in the reactions
    %

    % Initialize list of species
    model.species = { };
    
    % Get all species from reactants
    for i = 1:numel(model.reaction)
        for j = 1:numel(model.reaction(i).reactant)
            model.species{end+1} = model.reaction(i).reactant(j).species;
        end
    end
    
    % Get species from products
    for i = 1:numel(model.reaction)
        for j = 1:numel(model.reaction(i).product)
            model.species{end+1} = model.reaction(i).product(j).species;
        end
    end
    
    % Get only unique species
    model.species = unique(model.species);
    
    
    
    %
    % Step 2: Form incidence matrix I_a
    %
    
    % Count the number of species
    m = numel(model.species);
    
    % Initialize the matrix of reactant complexes
    reactant_complexes = [ ];
    
    % Initialize the matrix of product complexes
    product_complexes = [ ];
    
    % Initialize the stoichiometric matrix
    N = [ ];
    
    % For each reaction in the model
    for i = 1:numel(model.reaction)
      
        % Initialize the vector for the reaction's reactant complex
        reactant_complexes(:, end+1) = zeros(m, 1);
        
        % Fill it out with the stoichiometric coefficients of the species in the reactant complex
        for j = 1:numel(model.reaction(i).reactant)
            reactant_complexes(find(strcmp(model.reaction(i).reactant(j).species, model.species), 1), end) = model.reaction(i).reactant(j).stoichiometry;
        end
        
        % Initialize the vector for the reaction's product complex
        product_complexes(:, end+1) = zeros(m, 1);
        
        % Fill it out with the stoichiometric coefficients of the species in the product complex
        for j = 1:numel(model.reaction(i).product)
            product_complexes(find(strcmp(model.reaction(i).product(j).species, model.species), 1), end) = model.reaction(i).product(j).stoichiometry;
        end
        
        % Create a vector for the stoichiometric matrix: Difference between the two previous vectors
        N(:, end+1) = product_complexes(:, end) - reactant_complexes(:, end);
        
        % If the reaction is reversible
        if model.reaction(i).reversible
          
            % Insert a new vector for the reactant complex: make it same as the product complex
            reactant_complexes(:, end+1) = product_complexes(:, end);
            
            % Insert a new vector for the product complex: make it the same as the reactant complex
            product_complexes(:, end+1) = reactant_complexes(:, end-1);
            
            % Insert a new vector in the stoichiometric matrix: make it the additive inverse of the vector formed earlier
            N(:, end+1) = -N(:, end);
        end
    end
    
    % Count the total number of reactions
    r = size(N, 2);

    % Get just the unique complexes
    % index(i) is the index in all_complex of the reactant complex in reaction i
    [all_complex, ~, index] = unique([reactant_complexes product_complexes]', 'rows');
    
    % Construct the matrix of complexes
    all_complex = all_complex';
    
    % Count the number of complexes
    n = size(all_complex, 2);

    % Initialize matrix (complexes x total reactions) for the reacts_in relation
    % This is the incidence matrix I_a
    reacts_in = zeros(n, r);
    
    % Fill out the entries of the matrices
    for i = 1:r
        
        % reacts_in(i, r) = -1 and reacts_in(j, r) = 1) iff there is a reaction r: y_i -> y_j
        reacts_in(index(i), i) = -1;
        reacts_in(index(i+r), i) = 1;
    end

    % Construct the incidence matrix
    I_a = reacts_in;
    
    
    
    %
    % Step 3: Get the transpose of N: Each row now represents the reaction vector a reaction
    %
    
    R = I_a';
    
    
    
    %
    % Step 4: Form a basis for the rowspace of R
    %
    
    % Write R in reduced row echelon form: the transpose of R is used so 'basis_reaction_num' will give the pivot rows of R
    %    - 'basis_reaction_num' gives the row numbers of R which form a basis for the rowspace of R
    [~, basis_reaction_num] = rref(R');
    
    % Form the basis
    basis = R(basis_reaction_num, :);
    
    
    
    %
    % Step 5: Construct the vertex set of undirected graph G
    %
    
    % Initialize an undirected graph G
    G = graph();
    
    % Add vertices to G: these are the reaction vectors that form a basis for the rowspace of R
    for i = 1:numel(basis_reaction_num)
        
        % Use the reaction number as label for each vertex
        G = addnode(G, strcat('R', num2str(basis_reaction_num(i))));
    end
    
    
    
    %
    % Step 6: Write the nonbasis reaction vectors as a linear combination of the basis vectors
    %
    
    % Initialize matrix of linear combinations
    linear_combo = zeros(r, numel(basis_reaction_num));
    
    % Write the nonbasis reaction vectors as a linear combination of the basis vectors
    % Do this for the nonbasis reactions vectors
    for i = 1:r
        if ~ismember(i, basis_reaction_num)
          
          % This gives the coefficients of the linear combinations
          % The basis vectors will have a row of zeros
          linear_combo(i, :) = basis'\R(i, :)';
        end
    end
    
    % Round off values to nearest whole number to avoid round off errors
    linear_combination = round(linear_combo);
    
    
    
    %
    % Step 7: Construct the edge set of undirected graph G
    %
    
    % Get the reactions that are linear combinations of at least 2 basis reactions
    % These are the reactions where we'll get the edges
    get_edges = find(sum(abs(linear_combination), 2) > 1);
        
    % Initialize an array for sets of vertices that will form the edges
    vertex_set = { };
     
    % Identify which vertices form edges in each reaction: get those with non-zero coefficients in the linear combinations
    for i = 1:numel(get_edges)
        vertex_set{i} = find(linear_combination(get_edges(i), :) ~= 0);
    end
    
    % Initialize the edge set
    edges = [ ];
    
    % Get all possible combinations (not permutations) of the reactions involved in the linear combinations
    for i = 1:numel(vertex_set)
        edges = [edges; nchoosek(vertex_set{i}, 2)];
    end
    
    % Get just the unique edges
    edges = unique(edges, 'rows');
    
    % Add these edges to graph G
    for i = 1:size(edges, 1)
        G = addedge(G, strcat('R', num2str(basis_reaction_num(edges(i, 1)))), strcat('R', num2str(basis_reaction_num(edges(i, 2)))));
    end
    
    
    
    %
    % Step 8: Check if G is connected, i.e., has only one connected component
    %
    
    % Determine to which component each vertex belongs to
    component_numbers = conncomp(G);
    
    % Determine the number of connected components of G: this is the number of partitions R will be decomposed to
    num_components = max(component_numbers);
    
    % For the case of only one connected component
    if num_components == 1
        P = [ ];
        disp([model.id ' has no nontrivial incidence independent decomposition.']);
        
        % 'return' exits the function; we don't need to continue the code
        % If we wanted to just get out of the loop, we use 'break'
        return
    end
    
    
    
    %
    % Step 9: If G is NOT connected, form the partitions of R
    %
    
    % Initialize the list of partitions
    P = cell(1, num_components);
    
    % Basis vectors: assign them first into their respective partition based on their component number
    for i = 1:numel(component_numbers)
        P{component_numbers(i)}(end+1) = basis_reaction_num(i);
    end
    
    % Nonbasis vectors: they go to the same partition as the basis vectors that form their linear combination
    for i = 1:numel(P)
        for j = 1:numel(P{i})
            
            % Get the column number representing the basis vectors in 'linear_combination'
            col = find(basis_reaction_num == P{i}(j));
            
            % Check which reactions used a particular basis vector and assign them to their respective partition
            P{i} = [P{i} find(linear_combination(:, col) ~= 0)'];
        end
    end
    
    % Get only unique elements in each partition
    for i = 1:numel(P)
        P{i} = unique(P{i});
    end



    %
    % Step 10: Check if all the reactions are in the partitions
    %    - If not all reactions are partitions, usually it's because of the computation of linear combinations
    %

    % If some reactions are missing, then redo the end of Step 6 up to Step 9
    if length(cell2mat(P)) ~= size(R, 1)

        % Step 6 end: Do not round off the coefficients of the linear combinations
        linear_combination = linear_combo;

        % Step 7
        get_edges = find(sum(abs(linear_combination), 2) > 1);
        vertex_set = { };
        for i = 1:numel(get_edges)
            vertex_set{i} = find(linear_combination(get_edges(i), :) ~= 0);
        end
        edges = [ ];
        for i = 1:numel(vertex_set)
            edges = [edges; nchoosek(vertex_set{i}, 2)];
        end
        edges = unique(edges, 'rows');
        for i = 1:size(edges, 1)
            G = addedge(G, strcat('R', num2str(basis_reaction_num(edges(i, 1)))), strcat('R', num2str(basis_reaction_num(edges(i, 2)))));
        end
        
        % Step 8
        component_numbers = conncomp(G);
        num_components = max(component_numbers);
        if num_components == 1
            P = [ ];
            disp([model.id ' has no nontrivial independent decomposition.']);
            return
        end
        
        % Step 9
        P = cell(1, num_components);
        for i = 1:numel(component_numbers)
            P{component_numbers(i)}(end+1) = basis_reaction_num(i);
        end
        for i = 1:numel(P)
            for j = 1:numel(P{i})
                col = find(basis_reaction_num == P{i}(j));
                P{i} = [P{i} find(linear_combination(:, col) ~= 0)'];
            end
        end
        for i = 1:numel(P)
            P{i} = unique(P{i});
        end
    end
    
    
    
    %
    % Step 11: Display the independent decomposition
    %
    
    % Use 'fprintf' instead of 'disp' to interpret '\n' as 'newline'
    fprintf('Incidence Independent Decomposition - %s\n\n', model.id)
    for i = 1:numel(P)
        subnetwork = sprintf('R%d, ', P{i});
        subnetwork(end-1:end) = [ ]; % To clean the trailing comma and space at the end of the list
        fprintf('N%d: %s \n', i, subnetwork);
    end
    fprintf('\n')

end