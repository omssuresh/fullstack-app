import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService, User } from '../../services/auth.service';
import { AdminService } from '../../services/admin.service';
import { FilterPipe } from '../../pipes/filter.pipe';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, FormsModule, FilterPipe],
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.css']
})
export class AdminComponent implements OnInit {
  currentUser: User | null = null;
  users: any[] = [];
  loading = true;
  error = '';
  success = '';

  constructor(
    private authService: AuthService,
    private adminService: AdminService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.currentUser = this.authService.currentUserValue;
    
    // Check if user is admin
    if (!this.authService.isAdmin) {
      this.router.navigate(['/dashboard']);
      return;
    }

    this.loadUsers();
  }

  loadUsers(): void {
    this.loading = true;
    this.error = '';

    this.adminService.getAllUsers().subscribe({
      next: (response) => {
        if (response.success) {
          this.users = response.data.users;
        }
        this.loading = false;
      },
      error: (error) => {
        this.error = error.error?.message || 'Failed to load users';
        this.loading = false;
      }
    });
  }

  updateUserRole(userId: number, newRole: string): void {
    this.error = '';
    this.success = '';

    this.adminService.updateUserRole(userId, newRole).subscribe({
      next: (response) => {
        if (response.success) {
          this.success = 'User role updated successfully';
          this.loadUsers();
          setTimeout(() => this.success = '', 3000);
        }
      },
      error: (error) => {
        this.error = error.error?.message || 'Failed to update user role';
      }
    });
  }

  deleteUser(userId: number, username: string): void {
    if (!confirm(`Are you sure you want to delete user "${username}"?`)) {
      return;
    }

    this.error = '';
    this.success = '';

    this.adminService.deleteUser(userId).subscribe({
      next: (response) => {
        if (response.success) {
          this.success = 'User deleted successfully';
          this.loadUsers();
          setTimeout(() => this.success = '', 3000);
        }
      },
      error: (error) => {
        this.error = error.error?.message || 'Failed to delete user';
      }
    });
  }

  logout(): void {
    this.authService.logout();
  }

  goToDashboard(): void {
    this.router.navigate(['/dashboard']);
  }

  formatDate(dateString: string): string {
    return new Date(dateString).toLocaleDateString();
  }
}
