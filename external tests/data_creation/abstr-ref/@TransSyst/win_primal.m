function [V, Cv, cont] = win_primal(ts, A, B, C_list, quant1, quant2, V)
  % Compute winning set of
  %  []A && <>[]B &&_i []<>C_i
  % under (quant1, forall)-controllability
  % with the initial condition V ("warm start")
  %
  % Returns a sorted set
  %
  % Expanding algo
  
  if nargin<7
    V = [];
  end

  if isempty(A)
    A = uint32(1:ts.n_s);
  end
  if isempty(B)
    B = uint32(1:ts.n_s);
  end
  if isempty(C_list)
    C_list = {uint32(1:ts.n_s)};
  end

  if isa(quant1, 'char') && strcmp(quant1, 'exists')
    quant1_bool = true;
  elseif isa(quant2, 'char') && strcmp(quant1, 'forall')
    quant1_bool = false;
  else
    error('quantifier must be exists or forall')
  end

  if isa(quant2, 'char') && strcmp(quant2, 'exists')
    quant2_bool = true;
  elseif isa(quant2, 'char') && strcmp(quant2, 'forall')
    quant2_bool = false;
  else
    error('quantifier must be exists or forall')
  end

  if quant2_bool
    % Dualize
    cA = setdiff(uint32(1:ts.n_s), A);
    cB = setdiff(uint32(1:ts.n_s), B);
    cC_list = {};
    for i=1:length(C_list)
      cC_list{i} = setdiff(uint32(1:ts.n_s), C_list{i});
    end
    V = setdiff(uint32(1:ts.n_s), win_dual(cA, cC_list, cB, ~quant1_bool, ~quant2_bool));
    return
  end

  Vlist = {};
  Klist = {};

  V = uint32(V);
  A = sort(A);

  ts.create_fast();

  iter = 1;
  while true
    Z = ts.pre(V, [], quant1_bool, false);
    Z = union(Z, ts.pre_pg(V, A, quant1_bool));

    if nargout > 2
      [Vt, Ct, Kt] = ts.win_intermediate(A, B, Z, C_list, quant1_bool);
    elseif nargout > 1
      [Vt, Ct] = ts.win_intermediate(A, B, Z, C_list, quant1_bool);
    else
      Vt = ts.win_intermediate(A, B, Z, C_list, quant1_bool);
    end

    if nargout > 1 && iter == 1
      C_rec = Ct;
    end

    if length(Vt) == length(V)
      break
    end

    if nargout > 2
      Klist{end+1} = Kt;
      Vlist{end+1} = Vt;
    end

    V = Vt;
    iter = iter+1;
  end

  % Candidate set
  if nargout > 1
    Cv = union(setdiff(ts.pre(V, [], quant1_bool, true), V), C_rec);
  end

  % Controller
  if nargout > 2
    cont = Controller(Vlist, Klist, 'reach', 'win_primal');
  end
  
  persistent file_perm
  persistent test_count
  global run_setting
  if (strcmp(run_setting, 'write'))
      if isempty(file_perm)
          file_perm = 'w';
          test_count = 1;
      end

      test_count = test_count + 1;
      fileID = fopen('win_primal_test.txt', file_perm);
      disp('Writing to file');
      fprintf(fileID, 'test\n');
      fprintf(fileID, 'A ');
      fprintf(fileID, '%d ', [length(A), A]);
      fprintf(fileID, '\n');
      fprintf(fileID, 'B ');
      fprintf(fileID, '%d ', [length(B), B]);
      fprintf(fileID, '\n');
      fprintf(fileID, 'C %d', length(C_list));
      fprintf(fileID, '\n');
      for i = 1:length(C_list)
          fprintf(fileID, '%d ', [length(C_list{i}), C_list{i}]);
          fprintf(fileID, '\n');
      end
      if quant1_bool
          fprintf(fileID, 'q e\n');
      else
          fprintf(fileID, 'q a\n');
      end
      if quant2_bool
          fprintf(fileID, 'q e\n');
      else
          fprintf(fileID, 'q a\n');
      end
      fprintf(fileID, 'ans ');
      fprintf(fileID, '%d ', [length(V), V]);
      fprintf(fileID, '\n');
      fprintf(fileID, 'mode %d\n', nargout);
      if nargout > 1
          fprintf(fileID, 'cand ');
          fprintf(fileID, '%d ', [length(Cv), Cv]);
          fprintf(fileID, '\n');
      end
      fclose(fileID);
      file_perm = 'a';
      disp('closed file');

  end

end
