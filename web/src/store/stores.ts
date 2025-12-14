import { writable } from "svelte/store";

export const visibility = writable(false);
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
interface Grades {
    name: string;
    payment?: number;
    isboss?: boolean;
}

interface GroupData {
    name: string;
    label: string;
    type?: string;
    defaultDuty?: boolean;
    offDutyPay?: boolean;
    grades: {
        [key: string]: Grades;
    };
}

interface nearbyPlayers {
    citizenid: string;
    name: string;
}
interface language {
    currency: string;
    header: string;
    buttons: {
      recruit: string;
      stash: string;
      wardrobe: string;
      fire: string;
      cancel: string;
      confirm_fire: string;
    };
    employeeCard: {
      rank: string;
      pay: string;
      highest: string;
      fire: string;
    };
    no_employees: string;
    no_employees_desc: string;
    hire_employee_panel: {
      title: string;
      description: string;
      hire: string;
      no_players: string;
    };
    fire_employee_panel: {
      title: string;
      description: string;
      cant_be_undone: string;
      fire: string;
    };
    promotion_panel: {
      title: string;
      description: string;
      description2: string;
      warning: string;
      confirm_promote: string;
    };
}
export const employees = writable<Employee[] | null>(null);
export const groupData = writable<GroupData | null>(null);
export const nearbyPlayers = writable<nearbyPlayers[] | null>(null);
export const lang = writable<language | null>(null);