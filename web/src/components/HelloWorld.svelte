<script lang="ts">
  import { employees, groupData, nearbyPlayers, visibility, lang } from '../store/stores';
  import { fetchNui } from '../utils/fetchNui';

  interface Employee {
    jobData: {
      label: string;
      gradeLabel: string;
      name: string;
      pay: number;
      grade: number;
    };
    online: boolean;
    citizenid: string;
    name: string;
  }

  let showHireModal = false;
  let showFireModal = false;
  let employeeToFire: Employee | null = null;
  let showPromoteModal = false;
  let employeeToPromote: { employee: Employee; grade: number } | null = null;

  $: gradesArray = $groupData 
    ? Object.entries($groupData.grades)
        .map(([key, value]) => ({
          grade: parseInt(key),
          name: value.name,
          isboss: value.isboss,
          payment: value.payment || 0
        }))
        .sort((a, b) => a.grade - b.grade)
    : [];

  function openStorage() {
    fetchNui('openStorage');
    visibility.set(false);
  }

  function openWardrobe() {
    fetchNui('openWardrobe');
    visibility.set(false);
  }

  async function updateGrade(citizenid: string, newGrade: number) {
    employees.update(empList => {
      if (!empList || !$groupData) return empList;

      const idx = empList.findIndex(e => e.citizenid === citizenid);
      if (idx === -1) return empList;

      const employee = empList[idx];
      const oldGradeStr = employee.jobData.grade.toString();
      const newGradeStr = newGrade.toString();

      if ($groupData.grades[oldGradeStr]?.isboss) {
        return empList;
      }

      const gradeInfo = $groupData.grades[newGradeStr];
      if (!gradeInfo) return empList;

      if (gradeInfo.isboss ) {
        employeeToPromote = { employee, grade: newGrade };
        showPromoteModal = true;
        return empList;
      }

      const updatedEmployee: Employee = {
        ...employee,
        jobData: {
          ...employee.jobData,
          grade: newGrade,
          gradeLabel: gradeInfo.name,
          pay: gradeInfo.payment
        }
      };

      const newEmpList = [...empList];
      newEmpList[idx] = updatedEmployee;
      return newEmpList;
    });

    await fetchNui('updateGrade', { citizenid: citizenid, grade: newGrade });
  }

  async function fireEmployee(citizenid: string) {
    employees.update(empList => {
      if (!empList) return empList;
      return empList.filter(e => e.citizenid !== citizenid);
    });
    
    showFireModal = false;
    employeeToFire = null;
    await fetchNui('fireEmployee', { citizenid: citizenid });
  }

  async function confirmPromotion() {
    if (!employeeToPromote || !$groupData) return;

    const { employee, grade } = employeeToPromote;
    const gradeInfo = $groupData.grades[grade.toString()];
    if (!gradeInfo) {
      showPromoteModal = false;
      employeeToPromote = null;
      return;
    }

    employees.update(empList => {
      if (!empList) return empList;

      const idx = empList.findIndex(e => e.citizenid === employee.citizenid);
      if (idx === -1) return empList;

      const updatedEmp: Employee = {
        ...empList[idx],
        jobData: {
          ...empList[idx].jobData,
          grade,
          gradeLabel: gradeInfo.name,
          pay: gradeInfo.payment
        }
      };

      const newEmpList = [...empList];
      newEmpList[idx] = updatedEmp;
      return newEmpList;
    });

    fetchNui('updateGrade', { citizenid: employee.citizenid, grade: grade });
    showPromoteModal = false;
    employeeToPromote = null;
  }

  function openFireModal(employee: Employee) {
    employeeToFire = employee;
    showFireModal = true;
  }

  function hirePlayer(citizenid: string, name: string) {
    if (!$groupData || !$groupData.grades['0']) return;
    
    const firstGrade = $groupData.grades['0'];
    const newEmployee: Employee = {
      jobData: {
        label: $groupData.label,
        gradeLabel: firstGrade.name,
        name: $groupData.name,
        pay: firstGrade.payment,
        grade: '0'
      },
      online: true,
      citizenid: citizenid,
      name: name
    };
    
    employees.update(empList => {
      if (!empList) return [newEmployee];
      return [...empList, newEmployee];
    });

    nearbyPlayers.update(players => {
      if (!players) return players;
      return players.filter(p => p.citizenid !== citizenid);
    });
    showHireModal = false;
    fetchNui('hireEmployee', { citizenid: citizenid });
  }
</script>

<div class="container">
  <div class="header">
    <h1>{$groupData?.label || 'Job'} {$lang.header}</h1>
    <div class="header-actions">
      <button on:click={() => showHireModal = true} class="action-btn hire-btn">
        {$lang.buttons.recruit}
      </button>
      <button on:click={openStorage} class="action-btn">
        {$lang.buttons.stash}
      </button>
      <button on:click={openWardrobe} class="action-btn">
        {$lang.buttons.wardrobe}
      </button>
    </div>
  </div>

  <div class="content">
    {#if $employees && $employees.length > 0}
      <div class="employee-grid">
        {#each $employees as employee}
          <div class="employee-card">
            <div class="card-header">
              <div class="status-indicator" style="background-color: {employee.online ? '#22c55e' : '#ef4444'};"></div>
              <h3>{employee.name}</h3>
            </div>
            
            <div class="employee-info">
              <div class="info-row">
                <span class="label">{$lang.employeeCard.rank}</span>
                <span class="value">{employee.jobData.gradeLabel}</span>
              </div>
              {#if employee.jobData.pay !== undefined}
                <div class="info-row">
                  <span class="label">{$lang.employeeCard.pay}</span>
                  <span class="value">{$lang.currency}{employee.jobData.pay}</span>
                </div>
              {/if}
            </div>

            <div class="card-actions">
              {#if $groupData.grades[employee.jobData.grade.toString()]?.isboss}
                <span class="label">{$lang.employeeCard.highest}</span>
              {:else}
                  <select 
                    class="grade-select"
                    value={parseInt(employee.jobData.grade)}
                    on:change={(e) => updateGrade(employee.citizenid, parseInt(e.currentTarget.value))}
                  >
                    {#each gradesArray as grade}
                      <option value={grade.grade}>{grade.name}</option>
                    {/each}
                  </select>
                  <button 
                    class="fire-btn"
                    on:click={() => openFireModal(employee)}
                  >
                    {$lang.employeeCard.fire}
                  </button>
              {/if}
            </div>
          </div>
        {/each}
      </div>
    {:else}
      <div class="empty-state">
        <p>{$lang.no_employees}</p>
        <p class="empty-subtitle">{$lang.no_employees_desc}</p>
      </div>
    {/if}
  </div>
</div>

{#if showHireModal}
  <div class="modal-overlay" on:click={() => showHireModal = false}>
    <div class="modal" on:click|stopPropagation>
      <h2>{$lang.hire_employee_panel.title}</h2>
      <p class="modal-subtitle">{$lang.hire_employee_panel.description}</p>
      {#if $nearbyPlayers && $nearbyPlayers.length > 0}
        <div class="player-list">
          {#each $nearbyPlayers as player}
            <button 
              class="player-item"
              on:click={() => hirePlayer(player.citizenid, player.name)}
            >
              {player.name}
            </button>
          {/each}
        </div>
      {:else}
        <p class="no-players">{$lang.hire_employee_panel.no_players}</p>
      {/if}
      <button class="cancel-btn" on:click={() => showHireModal = false}>
        {$lang.buttons.cancel}
      </button>
    </div>
  </div>
{/if}

{#if showFireModal && employeeToFire}
  <div class="modal-overlay" on:click={() => { showFireModal = false; employeeToFire = null; }}>
    <div class="modal confirm-modal" on:click|stopPropagation>
      <h2>{$lang.fire_employee_panel.title}</h2>
      <p class="modal-subtitle">{$lang.fire_employee_panel.description} <strong>{employeeToFire.name}</strong>?</p>
      <p class="warning-text">{$lang.fire_employee_panel.cant_be_undone}</p>
      <div class="confirm-actions">
        <button class="cancel-btn" on:click={() => { showFireModal = false; employeeToFire = null; }}>
          {$lang.buttons.cancel}
        </button>
        <button class="confirm-fire-btn" on:click={() => fireEmployee(employeeToFire.citizenid)}>
          {$lang.fire_employee_panel.confirm_fire}
        </button>
      </div>
    </div>
  </div>
{/if}

{#if showPromoteModal && employeeToPromote && $lang}
  <button class="modal-overlay" on:click={() => { showPromoteModal = false; employeeToPromote = null; }} aria-label="Close promotion modal">
    <div class="modal confirm-modal" role="alertdialog" on:click|stopPropagation on:keydown|stopPropagation={(e) => e.key === 'Escape' && (showPromoteModal = false, employeeToPromote = null)}>
      <h2>{$lang?.promotion_panel?.title}</h2>
      <p class="modal-subtitle">{$lang?.promotion_panel?.description} <strong>{employeeToPromote!.employee.name}</strong>{$lang?.promotion_panel?.description2} <strong>{gradesArray.find(g => g.grade === employeeToPromote!.grade)?.name}</strong>?</p>
      <p class="warning-text">{$lang?.promotion_panel?.warning}</p>
      <div class="confirm-actions">
        <button class="cancel-btn" on:click={() => { showPromoteModal = false; employeeToPromote = null; }}>
          {$lang?.buttons?.cancel}
        </button>
        <button class="confirm-promote-btn" on:click={confirmPromotion}>
          {$lang?.promotion_panel?.confirm_promote}
        </button>
      </div>
    </div>
  </button>
{/if}

<style>
  .container {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    border-radius: 12px;
    width: 60%;
    max-width: 1200px;
    height: 70%;
    font-size: 14px;
    color: #d4d4d8;
    background: linear-gradient(145deg, #0f0f10, #1a1a1c);
    border: 1px solid #27272a;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .header {
    background: linear-gradient(to bottom, #1c1c1e, #18181a);
    padding: 24px 28px;
    border-bottom: 1px solid #2d2d30;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .header h1 {
    margin: 0;
    font-size: 24px;
    font-weight: 600;
    color: #ffffff;
    letter-spacing: -0.5px;
  }

  .header-actions {
    display: flex;
    gap: 10px;
  }

  .action-btn {
    padding: 10px 18px;
    border-radius: 6px;
    background-color: #222224;
    color: #d4d4d8;
    border: 1px solid #34343a;
    cursor: pointer;
    font-size: 13px;
    font-weight: 500;
    transition: all 0.15s ease;
    letter-spacing: 0.2px;
  }

  .action-btn:hover {
    background-color: #2a2a2e;
    border-color: #42424a;
    transform: translateY(-1px);
  }

  .action-btn:active {
    transform: translateY(0);
  }

  .hire-btn {
    background-color: #e63946;
    border-color: #e63946;
    color: #ffffff;
  }

  .hire-btn:hover {
    background-color: #d62839;
    border-color: #d62839;
  }

  .content {
    padding: 16px 22px;
    overflow-y: auto;
    flex: 1;
    background-color: #0f0f10;
  }

  .employee-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(240px, 0.5fr));
    gap: 14px;
  }

  .content::-webkit-scrollbar {
    display: none;
  }

  .employee-card {
    background: linear-gradient(135deg, #1a1a1c, #16161a);
    border: 1px solid #27272a;
    border-radius: 10px;
    padding: 18px;
    transition: all 0.2s ease;
  }

  .employee-card:hover {
    border-color: #34343a;
    transform: translateY(-2px);
  }

  .card-header {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 14px;
    padding-bottom: 12px;
    border-bottom: 1px solid #27272a;
  }

  .status-indicator {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background-color: #525258;
    flex-shrink: 0;
  }
  
  .card-header h3 {
    margin: 0;
    font-size: 15px;
    font-weight: 600;
    color: #ffffff;
    letter-spacing: -0.3px;
  }

  .employee-info {
    display: flex;
    flex-direction: column;
    gap: 10px;
    margin-bottom: 14px;
  }

  .info-row {
    display: flex;
    justify-content: space-between;
    font-size: 13px;
  }

  .label {
    color: #8a8a92;
    font-weight: 400;
  }

  .value {
    color: #d4d4d8;
    font-weight: 500;
  }

  .card-actions {
    display: flex;
    gap: 8px;
  }

  .grade-select {
    flex: 1;
    padding: 8px 12px;
    border-radius: 6px;
    background-color: #222224;
    color: #d4d4d8;
    border: 1px solid #34343a;
    cursor: pointer;
    font-size: 13px;
    transition: all 0.15s ease;
  }

  .grade-select:hover {
    border-color: #42424a;
    background-color: #2a2a2e;
  }

  .grade-select:focus {
    outline: none;
    border-color: #e63946;
  }

  .fire-btn {
    padding: 8px 14px;
    border-radius: 6px;
    background-color: #222224;
    color: #e63946;
    border: 1px solid #34343a;
    cursor: pointer;
    font-size: 13px;
    font-weight: 500;
    transition: all 0.15s ease;
  }

  .fire-btn:hover {
    background-color: #e63946;
    color: #ffffff;
    border-color: #e63946;
  }

  .empty-state {
    text-align: center;
    padding: 60px 20px;
    color: #8a8a92;
  }

  .empty-state p {
    margin: 0 0 8px 0;
    font-size: 16px;
    font-weight: 500;
    color: #d4d4d8;
  }

  .empty-subtitle {
    font-size: 14px;
    color: #6a6a72;
  }

  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .modal {
    background: linear-gradient(145deg, #16161a, #1a1a1c);
    border: 1px solid #27272a;
    border-radius: 12px;
    padding: 26px;
    width: 400px;
    max-width: 90%;
  }

  .confirm-modal {
    width: 450px;
  }

  .modal h2 {
    margin: 0 0 8px 0;
    font-size: 20px;
    font-weight: 600;
    color: #ffffff;
    letter-spacing: -0.5px;
  }

  .modal-subtitle {
    margin: 0 0 18px 0;
    font-size: 14px;
    color: #8a8a92;
    line-height: 1.5;
  }

  .modal-subtitle strong {
    color: #ffffff;
    font-weight: 600;
  }

  .warning-text {
    margin: 0 0 22px 0;
    font-size: 13px;
    color: #fbbf24;
    background-color: rgba(251, 191, 36, 0.08);
    padding: 12px 14px;
    border-radius: 6px;
    border-left: 2px solid #fbbf24;
  }

  .confirm-actions {
    display: flex;
    gap: 10px;
  }

  .confirm-actions .cancel-btn {
    width: auto;
    flex: 1;
  }

  .confirm-fire-btn {
    flex: 1;
    padding: 11px;
    border-radius: 6px;
    background-color: #e63946;
    color: #ffffff;
    border: 1px solid #e63946;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    transition: all 0.15s ease;
  }

  .confirm-fire-btn:hover {
    background-color: #d62839;
    border-color: #d62839;
    transform: translateY(-1px);
  }

  .confirm-fire-btn:active {
    transform: translateY(0);
  }

  .confirm-promote-btn {
    flex: 1;
    padding: 11px;
    border-radius: 6px;
    background-color: #e63946;
    color: #ffffff;
    border: 1px solid #e63946;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    transition: all 0.15s ease;
  }

  .confirm-promote-btn:hover {
    background-color: #d62839;
    border-color: #d62839;
    transform: translateY(-1px);
  }

  .confirm-promote-btn:active {
    transform: translateY(0);
  }

  .player-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-bottom: 18px;
  }

  .player-item {
    padding: 12px 16px;
    border-radius: 6px;
    background-color: #222224;
    color: #d4d4d8;
    border: 1px solid #34343a;
    cursor: pointer;
    font-size: 14px;
    text-align: left;
    transition: all 0.15s ease;
  }

  .player-item:hover {
    background-color: #2a2a2e;
    border-color: #42424a;
    transform: translateX(4px);
  }

  .player-item:active {
    transform: translateX(2px);
  }

  .no-players {
    margin: 0 0 18px 0;
    padding: 18px;
    text-align: center;
    color: #6a6a72;
    background-color: #222224;
    border-radius: 6px;
    font-size: 13px;
  }

  .cancel-btn {
    width: 100%;
    padding: 11px;
    border-radius: 6px;
    background-color: #222224;
    color: #d4d4d8;
    border: 1px solid #34343a;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
    transition: all 0.15s ease;
  }

  .cancel-btn:hover {
    background-color: #2a2a2e;
    border-color: #42424a;
  }
</style>