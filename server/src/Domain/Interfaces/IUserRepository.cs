using HabitTracker.Domain.Entities;
using System.Threading.Tasks;

namespace HabitTracker.Domain.Interfaces
{
    public interface IUserRepository
    {
        Task<ApplicationUser?> GetByIdAsync(string id);
        Task UpdateAsync(ApplicationUser user);
    }
}
